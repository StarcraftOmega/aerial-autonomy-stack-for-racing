# Drone Racing Autonomy Stack

A PX4-first autonomy and simulation stack for vision-based drone racing, built on top of the original `aerial-autonomy-stack` architecture.

This repository keeps the multi-container AAS workflow (simulation, aircraft, ground), but is organized and used here primarily for:

- fast quadcopter iteration
- camera-driven autonomy
- Gymnasium-based RL experiments
- sim-to-real-friendly deployment workflows (amd64 simulation, arm64 Jetson deployment)

## What This Repo Includes

- PX4 SITL + Gazebo Harmonic simulation
- ROS 2 autonomy stack in `aircraft/aircraft_ws/src`
- Camera pipeline and YOLO node scaffold (`yolo_py`)
- Offboard control path for agile flight (`offboard_control` + `autopilot_interface`)
- Gymnasium environment package (`aas-gym`) for stepped and speed-up execution
- Dockerized workflows for simulation (`sim_*`) and deployment (`deploy_*`)

## Current Racing-Relevant Structure

```text
aerial-autonomy-stack-for-racing/
├── aas-gym/
│   └── src/aas_gym/aas_env.py                 # Gymnasium env wrapper around Dockerized sim
├── aircraft/
│   ├── aircraft_resources/
│   └── aircraft_ws/src/
│       ├── autopilot_interface/               # ROS2 Actions/Services (takeoff, land, offboard, etc.)
│       ├── autopilot_interface_msgs/
│       ├── mission/                           # Mission orchestration entrypoint
│       ├── offboard_control/                  # Low-level offboard references
│       ├── state_sharing/
│       └── yolo_py/                           # Vision pipeline / detections publisher
├── ground/
│   └── ground_ws/src/ground_system/
├── scripts/
│   ├── check_requirements.sh
│   ├── sim_build.sh
│   ├── sim_run.sh
│   ├── deploy_build.sh
│   └── deploy_run.sh
├── simulation/
│   ├── simulation.yml.erb
│   └── simulation_resources/
│       ├── aircraft_models/
│       │   ├── x500/                          # PX4 quad model
│       │   └── sensor_config.yaml
│       └── simulation_worlds/
│           ├── impalpable_greyness.sdf
│           └── racing_gate/                   # Racing gate model assets
└── github_clones/                             # Auto-populated by sim_build.sh
```

## Prerequisites

Host-side requirements are checked with:

```bash
cd scripts
./check_requirements.sh
```

Recommended baseline (from scripts and docs):

- Ubuntu 22.04 or 24.04
- Docker Engine
- NVIDIA Container Toolkit
- NVIDIA GPU driver compatible with this stack
- `git`, `xterm`, `xfonts-base`, `wget`, `unzip`

## 1) Installation

```bash
git clone <https://github.com/StarcraftOmega/aerial-autonomy-stack-for-racing.git>
cd aerial-autonomy-stack-for-racing/scripts

# Validate host dependencies
./check_requirements.sh

# Build images and fetch pinned upstream dependencies into github_clones/
./sim_build.sh
```

Notes:

- First build can be large and take significant time.
- `sim_build.sh` clones PX4, ArduPilot, mavlink-router, flight_review, etc., at pinned refs.

## 2) Run Simulation (PX4 Quad, Racing-Friendly Defaults)

```bash
cd scripts
./sim_run.sh
```

Important behavior from current `sim_run.sh`:

- `LIDAR` is currently forced to `false` in the script.
- Default autopilot is PX4.
- Default world is `impalpable_greyness`.
- One `Simulation` xterm + `Ground` xterm + one or more aircraft xterms are launched.

After startup, allow SITL and estimators to initialize before aggressive maneuvers.

## 3) Development Workflow (No Full Rebuild Loop)

Use DEV mode to mount workspace folders directly into containers:

```bash
cd scripts
DEV=true AUTOPILOT=px4 NUM_QUADS=1 WORLD=impalpable_greyness HEADLESS=false RTF=3.0 ./sim_run.sh
```

Then build code changes from inside the relevant container terminal:

```bash
cd /aas/aircraft_ws
colcon build --symlink-install
```

You can restart tmux-managed processes in each container without rebuilding images.

## 4) Gymnasium / RL Usage

Install the gym package:

```bash
cd aas-gym
pip3 install -e .
```

Run example modes:

```bash
cd scripts
python3 gym_run.py --mode step
python3 gym_run.py --mode speedup
python3 gym_run.py --mode vectorenv-speedup
```

Key points from current implementation:

- Environment ID: `AASEnv-v0`
- Supports headless faster-than-real-time stepping (`RTF=0` behavior in env path)
- Vectorized mode is available through `AsyncVectorEnv`

## 5) Jetson / Edge Deployment

Build arm64 aircraft image on Jetson:

```bash
cd scripts
./deploy_build.sh
```

Run aircraft container on Jetson:

```bash
AUTOPILOT=px4 DRONE_ID=1 CAMERA=true HEADLESS=true ./deploy_run.sh
```

For HITL and multi-node networking, use the `HITL`, `SIM_SUBNET`, and `AIR_SUBNET` options in `deploy_run.sh` and `sim_run.sh`.

## Useful Flags

### `sim_run.sh`

- `AUTOPILOT=px4|ardupilot`
- `NUM_QUADS=1..N`
- `WORLD=<world_name>`
- `HEADLESS=true|false`
- `CAMERA=true|false`
- `RTF=<float>`
- `DEV=true|false`
- `HITL=true|false`
- `INSTANCE=<int>`

### `deploy_run.sh`

- `AUTOPILOT=px4|ardupilot`
- `DRONE_ID=<int>`
- `HEADLESS=true|false`
- `CAMERA=true|false`
- `HITL=true|false`
- `GROUND=true|false`

## Status and Scope

This repository is actively usable for racing-oriented PX4 quad workflows, while still retaining broader upstream AAS components in the build and simulation templates (for example ArduPilot-related assets).
