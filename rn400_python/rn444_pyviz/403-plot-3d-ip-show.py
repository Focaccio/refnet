"""
================
Basic matplotlib
================

A basic example of 3D Graph visualization using `mpl_toolkits.mplot3d`,
with CSV input for nodes and edges, supporting IP addresses as node identifiers,
and displaying IP addresses as labels in the graph.
"""

import networkx as nx
import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import csv

# Prompt for CSV files
nodes_file = input("Enter the path to the nodes CSV file: ")
edges_file = input("Enter the path to the edges CSV file: ")

# Read nodes from CSV
G = nx.Graph()
with open(nodes_file, 'r') as f:
    reader = csv.reader(f)
    next(reader)  # Skip header
    for row in reader:
        # Treat the first column (node identifier) as a string
        G.add_node(str(row[0]), pos=(float(row[1]), float(row[2]), float(row[3])))

# Read edges from CSV
with open(edges_file, 'r') as f:
    reader = csv.reader(f)
    next(reader)  # Skip header
    for row in reader:
        # Treat both source and target as strings
        G.add_edge(str(row[0]), str(row[1]))

# Extract node and edge positions
pos = nx.get_node_attributes(G, 'pos')
node_xyz = np.array([pos[v] for v in G.nodes()])
edge_xyz = np.array([(pos[u], pos[v]) for u, v in G.edges()])

# Create the 3D figure
fig = plt.figure(figsize=(12, 8))
ax = fig.add_subplot(111, projection="3d")

# Plot the nodes
ax.scatter(*node_xyz.T, s=100, ec="w")

# Plot the edges
for vizedge in edge_xyz:
    ax.plot(*vizedge.T, color="tab:gray")

# Add node labels (IP addresses)
for node, (x, y, z) in pos.items():
    ax.text(x, y, z, node, fontsize=8)

# ... rest of the code remains unchanged ...

def _format_axes(ax):
    """Visualization options for the 3D axes."""
    # Turn gridlines off
    ax.grid(False)
    # Suppress tick labels
    for dim in (ax.xaxis, ax.yaxis, ax.zaxis):
        dim.set_ticks([])
    # Set axes labels
    ax.set_xlabel("x")
    ax.set_ylabel("y")
    ax.set_zlabel("z")

_format_axes(ax)
fig.tight_layout()
plt.show()