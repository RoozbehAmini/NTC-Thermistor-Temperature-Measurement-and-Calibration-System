# NTC Thermistor Temperature Measurement (0 to 100 °C)

Arduino and MATLAB code for a calibrated NTC thermistor thermometer: a 10 kΩ NTC in a voltage divider, a unity-gain difference amplifier (LM741) that shifts 0 °C to 0 V, and an external ADC reference that maps 100 °C to full scale on an Arduino Uno.

Measurement Systems Lab, Session 06, University of Tehran (Instructor: Dr. Ali Sadighi), February 2026. The lab report, [`Lab6_Project_Report.pdf`](Lab6_Project_Report.pdf), covers the circuit design, theory, data collection, MATLAB analysis and verification.

## Results

The fitted beta model gives β = 3578.29 K and R0 = 9835.46 Ω at 25 °C. With the 3.325 V reference, one ADC step is about 3.25 mV, compared with about 4.9 mV on the default 5 V reference. In the final check, the thermometer differed from the medical thermometer by 0.08 °C.

## Repository layout

```
Arduino/
  calibration_logger/      50 Hz, 60 s logger used for every calibration point
  live_voltage_reader/     2 Hz voltmeter used to set the two trimmer pots
  temperature_firmware/    final thermometer firmware (external AREF)
Matlab/
  acquire_calibration_point.m   reads one 60 s record over serial, saves it, appends to master list
  fit_beta_model.m              fits the beta model, extrapolates to 100 °C, saves figures
```

The MATLAB scripts create `data/` (raw traces and `calibration_master_list.csv`) and `figures/` next to the `Matlab/` folder.

## Signal chain

```
5V --[10k]--+--[NTC]-- GND
            |
           Vth --> diff amp (V-)          all four diff-amp resistors = 1 MΩ
Pot 1 (3.730 V) --> diff amp (V+)
diff amp output = 3.730 - Vth --> A0
Pot 2 (3.325 V) --[5k]--> AREF
```

The firmware inverts each stage: ADC count → V_adc → V_th = 3.730 − V_adc → R_th = 10k · V_th / (5 − V_th) → T from the beta model.

## Workflow

1. Wire the divider node straight to A0 and upload `calibration_logger`. For each bath, wait for the reference thermometer to settle, then run `acquire_calibration_point.m` (set `port` first). Opening the port resets the Uno, so every run records a fresh 60 s trace. The last 10 s are averaged.
2. Run `fit_beta_model.m`. It prints β, R0, the per-point residuals in °C, and the model's diff-amp output at 100 °C (the V_AREF target). If `data/calibration_master_list.csv` is missing, it uses the eight points below.
3. Upload `live_voltage_reader` to set the pots. Set pot 1 to 3.730 V (wiper on A2), then change `PIN_ANALOG` to `A1` and set pot 2.
4. Copy β, R0, V_AREF and the 0 °C reference into `temperature_firmware` and upload it. It prints `V_adc,V_th,R_th,Temp_C` at 2 Hz (9600 baud).

> The AREF pin has an internal resistance of about 32 kΩ, so the 5 kΩ protection resistor forms a divider with it. With `temperature_firmware` running, measure the voltage at the AREF pin itself with a multimeter and use that value for `V_AREF`.

## Calibration data

| T (°C) | R_th (Ω) | Source |
|---:|---:|---|
| 0.0 | 29 498.05 | Ice bath |
| 33.2 | 7 241.27 | Mixed bath + medical thermometer |
| 34.4 | 6 832.37 | Mixed bath + medical thermometer |
| 35.3 | 6 585.11 | Mixed bath + medical thermometer |
| 37.0 | 6 135.16 | Mixed bath + medical thermometer |
| 37.8 | 5 944.50 | Mixed bath + medical thermometer |
| 38.2 | 5 892.11 | Mixed bath + medical thermometer |
| 90.0 | 1 135.84 | Boiling water (assigned 90 °C) |

Water boils below 100 °C at Tehran's altitude and cooled quickly during the measurement, so the boiling-water point was assigned 90 °C.

## Requirements

- Arduino Uno and the Arduino IDE (no extra libraries)
- MATLAB R2023a or newer (`xregion`); the acquisition script alone needs R2019b+ (`serialport`)

## Authors

Roozbeh Amini, Masih Shanesazzadeh, Mehran Feizi
