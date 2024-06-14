import math

def calculate_rssi(d):
    lambda_val = 0.125
    rssi = -20 * math.log10((d * 4 * math.pi) / lambda_val)
    return rssi

d = float(input("Enter the distance in meters: "))
rssi = calculate_rssi(d)
print("Calculated RSSI:", rssi)
