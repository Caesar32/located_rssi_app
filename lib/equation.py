import math

def calculate_distance(rssi):
    c = 3 * 10**8  # Speed of light in meters/second
    lambda_val = 0.125  # Wavelength in meters
    frequency = c / lambda_val  # Frequency in Hz
    
    # FSPL components calculation
    FSPL_constant = 20 * math.log10(frequency) + 20 * math.log10(4 * math.pi / c)
    
    # Distance calculation
    distance = 10 ** ((rssi + FSPL_constant) / -20)
    return distance

# Input RSSI value from user
rssi = float(input("Enter RSSI in dBm: "))

# Calculate and print the distance
distance = calculate_distance(rssi)
print(f"Calculated Distance: {distance:.3f} meters")
