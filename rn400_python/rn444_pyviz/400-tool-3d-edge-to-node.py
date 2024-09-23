import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

def create_nodes_csv(edges_csv_path='edges.csv', nodes_csv_path='nodes.csv', visualize=True):
    # Read the edges CSV
    edges_df = pd.read_csv(edges_csv_path)
    
    # Extract unique IP addresses
    all_ips = pd.concat([edges_df['source'], edges_df['destination']]).unique()
    
    # Create a layout for the nodes in 3D space
    num_nodes = len(all_ips)
    
    # Generate random points within a unit sphere
    phi = np.random.uniform(0, 2*np.pi, num_nodes)
    costheta = np.random.uniform(-1, 1, num_nodes)
    u = np.random.uniform(0, 1, num_nodes)

    theta = np.arccos(costheta)
    r = u**(1/3)

    x = r * np.sin(theta) * np.cos(phi)
    y = r * np.sin(theta) * np.sin(phi)
    z = r * np.cos(theta)
    
    # Create the nodes dataframe
    nodes_df = pd.DataFrame({
        'id': all_ips,
        'x': x,
        'y': y,
        'z': z
    })
    
    # Save to CSV
    nodes_df.to_csv(nodes_csv_path, index=False)
    
    print(f"Nodes CSV created at {nodes_csv_path}")
    
    if visualize:
        # Visualize the layout in 3D
        fig = plt.figure(figsize=(10, 10))
        ax = fig.add_subplot(111, projection='3d')
        ax.scatter(x, y, z)
        for i, ip in enumerate(all_ips):
            ax.text(x[i], y[i], z[i], ip, fontsize=8)
        ax.set_title("3D Node Layout Visualization")
        ax.set_xlabel('X')
        ax.set_ylabel('Y')
        ax.set_zlabel('Z')
        plt.savefig('node_layout_3d.png')
        print("3D Visualization saved as node_layout_3d.png")

# Usage
create_nodes_csv()