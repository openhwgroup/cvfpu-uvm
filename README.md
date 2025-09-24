# CVFPU UVM Testbench

## 1. Project Overview
This repository contains a **UVM testbench** for verifying the **CVFPU (Core-V Floating Point Unit)**. DUT is the CVA6 wrapper of the floating point unit.

## 2. Testbench Architecture

![CVA6 Tile Platform](./images/cvfpu_uvm_tb_archi.png)

## 3. Project Structure
The repository is organised as follows:
- **env/** Contains UVM environment, scoreboard and top configuration class
- **fpu_agent/** Contains UVM agent, driver, sequencer, monitor, interface, sequences and transaction
- **fpu_common/** Contains package used accross UVM testbench
- **ref_model_csim/** Contains C++ reference model as well as SV wrapper
- **simu/** Contains regression test list and yaml files needed to run simulation and regression scripts. It also holds log files
- **tests/** Contains UVM test classes
- **top/** Contains top-level testbench file.

## 4. Getting started
### 4.1. Compile C++ Reference Model 
The first step is to build the shared library `refmodel_csim_lib.so` that will be used in the UVM testbench via DPI.

#### Dependencies
The following dependencies need to be installed in the system:

- **GMP** (GNU Multiple Precision Arithmetic Library)
- **MPFR** (Multiple Precision Floating-Point Reliable Library): Section [*2.1 How to Install*](https://www.mpfr.org/mpfr-current/mpfr.html) details the steps to follow to install the library, use preferably version **4.2.2**.

Then, set GMP/MPFR directory path variables in the environment
```
setenv GMP_DIR <gmp_dir_path>
setenv MPFR_DIR <mpfr_dir_path>
```

#### Compilation
```
cd ./ref_model_csim/cpp/
make
```

### 4.2. Build and run simulation 
#### Setup

At the root of the project, set the following environment variables.
```
setenv QUESTA_PATH <questa_path> 
   # ex: setenv QUESTA_PATH <path_to_your_install>/questasim/2025.1
   which vsim: <path_to_your_install>/questasim/2025.1/bin/vsim
setenv PATH ${QUESTA_PATH}/bin:$PATH
```
Run the setup script to configure project paths.
```
source setup_env.csh
```

#### Build TB and run simulation
1. Compile testbench
```
cd simu
python3 ${SCRIPTS_DIR}/compile.py --yaml sim_questa.yaml
```
2. Run a test

The number of transactions is set by the variable `+NB_TXNS` (passed as simulation option) in the `sim_questa.yaml` script. It is currently fixed to 10 000.
```
python3 ${SCRIPTS_DIR}/run_test.py --yaml sim_questa.yaml --test_name <TEST_NAME> --seed <SEED> --debug <VERBOSITY>
```
For example
```
python3 ${SCRIPTS_DIR}/run_test.py --yaml sim_questa.yaml --test_name fpu_random_test --seed 1 --debug UVM_LOW
```
Simulation logs can be found in the `output/` directory.

3. Run a regression, `fpu_reg_list` contains the regression suite.
```
python3 ${SCRIPTS_DIR}/run_reg.py --yaml reg_questa.yaml --nthreads 3 --reg_list fpu_reg_list
```
Regression logs can be found in the `regression` folder. To parse through them, run the following script which will return result of the tests with either PASS or FAIL.
```
scan_logs.pl -nowarn --pat ${PROJECT_DIR}/scripts/patterns/sim_patterns.pat --waiver ${PROJECT_DIR}/scripts/patterns/sim_waivers.pat regression/fpu_*_test_*.log
```
