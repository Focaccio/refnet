import csv
from collections import defaultdict

def process_csv(input_file, nodes_output, edges_output):
    nodes = set()
    edges = defaultdict(int)

    # Read the input CSV file
    with open(input_file, 'r') as f:
        reader = csv.DictReader(f)
        headers = reader.fieldnames

        # Determine the correct column names
        source_col = next((col for col in headers if 'source' in col.lower()), None)
        dest_col = next((col for col in headers if 'destination' in col.lower()), None)
        proto_col = next((col for col in headers if 'protocol' in col.lower()), None)

        if not all([source_col, dest_col, proto_col]):
            raise ValueError("Couldn't find required columns in the CSV. Please check the file format.")

        for row in reader:
            source = row[source_col]
            destination = row[dest_col]
            protocol = row[proto_col]

            # Add nodes
            nodes.add(source)
            nodes.add(destination)

            # Add edge
            edge = (source, destination, protocol)
            edges[edge] += 1

    # Write nodes to CSV
    with open(nodes_output, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['Id', 'Label'])
        for node in nodes:
            writer.writerow([node, node])

    # Write edges to CSV
    with open(edges_output, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['Source', 'Target', 'Type', 'Weight', 'Protocol'])
        for (source, target, protocol), weight in edges.items():
            writer.writerow([source, target, 'Directed', weight, protocol])

# Usage
input_file = 'wireshark_export.csv'
nodes_output = 'nodes.csv'
edges_output = 'edges.csv'
process_csv(input_file, nodes_output, edges_output)