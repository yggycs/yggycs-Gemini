import pandas as pd
import sys
input_file = sys.argv[1] 
output_file = "./Fig_5.csv" 

df = pd.read_csv(input_file)
df = df.drop(['mm', 'ss', 'ff', 'rr'], axis=1)
df = df.rename(columns={'nn': 'network_id', 'xx': 'X_line', 'yy': 'y_line', 'bb': 'batch_size','cost_compute':'MC_compute_die','cost_IO':'MC_IO','cost_os_overall':'MC_os', 'idx':'MAP_type'})
df['intra-core'] = df['ubuf'] + df['buf'] + df['bus'] + df['mac.1']
df = df.drop(['ubuf', 'buf', 'bus', 'mac.1'], axis=1)
df['NoC'] = df['NoC'] - df['NoP'] * 1.2 / 2
df['NoP'] = df['NoP'] * 1.2 / 2 + df['DRAM'] * 1.2 / 10.5
df['DRAM'] = df['DRAM'] * (10.5 - 1.2) / 10.5
df['Network_energy'] = df['NoC'] + df['NoP']
df = df.drop(['NoC', 'NoP'], axis=1)
df = df.rename(columns={'cost_overall': 'MC', 'cost': 'MC*E*D'})
df['MAP_type'] = df['MAP_type'].replace({0: 'T-MAP', 3: 'G-MAP'})
df = df.rename(columns={'intra-core': 'intra_core_energy', 'DRAM': 'DRAM_energy'})
df = df.drop(['compute_die_area', 'IO_die_area', 'os_area','cost_soc'], axis=1)
columns = df.columns.tolist()
columns.remove('DRAM_energy')
columns.insert(columns.index('Network_energy') + 1, 'DRAM_energy')
df = df[columns]
network_id_mapping = {6: 'IRes', 2: 'RN-50', 11: 'TF', 12: 'PNas', 13: 'RNX'}
df['network_id'] = df['network_id'].replace(network_id_mapping)
df.to_csv(output_file, index=False)
print("Process succeed.")