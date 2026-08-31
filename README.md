# NTC Thermistor Temperature Measurement and Calibration System

This repository contains the hardware design, calibration data, MATLAB scripts, and Arduino firmware for a complete NTC thermistor temperature measurement system.

This project was developed as **Lab Session #6** for the Measurement Systems course at the University of Tehran (Instructed by Dr. Ali Sadighi).

## Project Overview

The objective of this project is to design, calibrate, and verify a temperature measurement system built around a 10 kΩ NTC thermistor, a unity-gain difference amplifier, and an Arduino Uno. Because NTC thermistors have a strongly nonlinear resistance-temperature characteristic, the project required a physics-based calibration model ($\beta$-parameter equation) and careful signal conditioning before interfacing with the microcontroller's ADC.

The final system maps the Arduino's 10-bit ADC full scale to the nominal 0–100°C measurement range, achieving a voltage resolution of 3.25 mV/step—a 33.5% improvement over the default 5V reference. Final verification showed a discrepancy of only 0.08°C against a medical thermometer reference.

## System Architecture

The signal conditioning circuit consists of four series stages to accurately map the thermistor's non-linear output to the Arduino:

* **Stage 1: Thermistor Voltage Divider:** Converts the NTC thermistor's variable resistance into a voltage signal ($V_{th}$).
* **Stage 2: Reference Voltage Generator (3.73 V):** A potentiometer-based adjustable voltage divider calibrated using a 0°C ice bath to establish a stable reference.
* **Stage 3: Unity-Gain Difference Amplifier:** Subtracts the 3.73 V reference from the thermistor signal using an LM741 op-amp and four 1 MΩ resistors (chosen to satisfy the 10x impedance loading rule).
* **Stage 4: External ADC Reference (3.325 V):** A secondary potentiometer providing a custom AREF voltage to the Arduino. This value was derived by extrapolating the fitted $\beta$-model to 100°C, ensuring the full 1023 ADC steps are utilized for the target temperature range.

## Calibration Process

Due to instrument constraints (a medical thermometer with a valid reading range of 32–43°C), calibration was anchored using physical fixed points and mathematical extrapolation:

1. **Low Anchor (0°C):** An ice bath established the thermodynamic fixed point, yielding the Stage 2 reference voltage ($V_{ref} = 3.73$ V).
2. **High Anchor (~90°C):** Boiling water (reduced from 100°C due to Tehran's altitude and rapid cooling) was used to capture high-temperature resistance behavior.
3. **Intermediate Points (33–38°C):** Mixed hot and cold baths were measured against a clinical medical thermometer.
4. **MATLAB Modeling:** The 8 recorded points were fitted to a linearized $\beta$-parameter model using least-squares regression, yielding $\beta = 3578.29$ K and $R_0 = 9835.46$ Ω.

## Repository Contents

* `Lab6_Project_Report.pdf`: Comprehensive documentation of the circuit design, theoretical background, data collection process, MATLAB analysis, and final verification.
* *(Note: Add your firmware, MATLAB `.m` scripts, and raw `.csv` data files to their respective folders when uploading the code to this repository)*

## Authors & Contributors

* **Roozbeh Amini**
* **Masih Shanesazzadeh**
* **Mehran Feizi**

**Date:** February 2026
