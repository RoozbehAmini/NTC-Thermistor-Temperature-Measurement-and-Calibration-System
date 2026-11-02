/*
 * Final Temperature Measurement Firmware
 * Measurement Systems Lab, Session 06 - University of Tehran
 *
 * Forward signal chain:
 *   5V --[10k]--+--[Thermistor]-- GND
 *               |
 *              Vth --> Diff-Amp (V-)
 *   Pot-1 (3.730 V) --> Diff-Amp (V+)
 *   Diff-Amp output --> A0
 *   Pot-2 (3.325 V) --> [5k] --> AREF
 *
 * Firmware inversion:
 *   V_adc = (ADC / 1023) * V_AREF          (undo ADC scaling)
 *   V_th  = V_FIXED_REF - V_adc            (undo Stage 3 diff amp)
 *   R_th  = R_SERIES * V_th / (Vcc - V_th) (undo Stage 1 divider)
 *   T[C]  = 1 / (1/T0 + ln(R/R0)/beta) - 273.15
 *
 * V_AREF = 3.325 V derived from the beta model at 100 C:
 *   R(100 C) = 881.4 Ohm -> Vth(100 C) = 0.405 V
 *   Vout(100 C) = 3.730 - 0.405 = 3.325 V -> AREF
 *
 * AREF note: the AREF pin has an internal ~32k resistance, so the 5k
 * protection resistor forms a divider with it. Set V_AREF to the voltage
 * measured with a multimeter AT THE AREF PIN while this sketch is running,
 * not the voltage at the pot wiper.
 */

// --- Calibration constants (from MATLAB beta-model fit) ---
const float V_AREF      = 3.325f;    // model extrapolation to 100 C (see AREF note)
const float V_FIXED_REF = 3.730f;    // Pot-1: V_th at 0 C (ice bath)
const float R_SERIES    = 10000.0f;
const float VCC         = 5.0f;
const float R0          = 9835.46f;  // Ohm at 25 C
const float BETA        = 3578.29f;  // K
const float T0_K        = 298.15f;   // 25 C

const int SENSOR_PIN = A0;

float reconstruct_Vtherm(float v_adc);
float compute_Rtherm(float v_therm);
float compute_Temperature(float R_therm);

void setup() {
  analogReference(EXTERNAL);         // MUST be first, before any analogRead()
  analogRead(SENSOR_PIN);            // discard first reading after reference change
  Serial.begin(9600);
  while (!Serial) { ; }
  Serial.println("V_adc,V_th,R_th,Temp_C");
}

void loop() {
  int   adc     = analogRead(SENSOR_PIN);
  float v_adc   = (float)adc / 1023.0f * V_AREF;
  float v_therm = reconstruct_Vtherm(v_adc);
  float R_therm = compute_Rtherm(v_therm);
  float tempC   = compute_Temperature(R_therm);

  Serial.print(v_adc, 4);   Serial.print(",");
  Serial.print(v_therm, 4); Serial.print(",");
  Serial.print(R_therm, 2); Serial.print(",");
  Serial.println(tempC, 2);

  delay(500);                        // 2 Hz
}

float reconstruct_Vtherm(float v_adc) {
  return V_FIXED_REF - v_adc;
}

float compute_Rtherm(float v_therm) {
  if (v_therm <= 0.01f) v_therm = 0.01f;
  if (v_therm >= 4.99f) v_therm = 4.99f;
  return R_SERIES * (v_therm / (VCC - v_therm));
}

float compute_Temperature(float R_therm) {
  float inv_T = (1.0f / T0_K) + (logf(R_therm / R0) / BETA);
  return (1.0f / inv_T) - 273.15f;
}
