import csv
from collections import defaultdict

def get_column_name(headers, column_type):
    print(f"\nAvailable columns: {', '.join(headers)}")
    while True:
        col_name = input(f"Enter the name of the {column_type} column: ").strip()
        if col_name in headers:
            return col_name
        print(f"Column '{col_name}' not found. Please try again.")

def process_csv(input_file, nodes_output, edges_output):
    nodes = set()
    edges = defaultdict(int)

    # Read the input CSV file
    with open(input_file, 'r') as f:
        reader = csv.DictReader(f)
        headers = reader.fieldnames

        print("Please specify the column names for Source IP, Destination IP, and Protocol.")
        source_col = get_column_name(headers, "Source IP")
        dest_col = get_column_name(headers, "Destination IP")
        proto_col = get_column_name(headers, "Protocol")

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

    print(f"\nProcessing complete. Output files created: {nodes_output} and {edges_output}")

# Usage
input_file = input("Enter the name of your Wireshark CSV export file: ").strip()
nodes_output = input("Enter the name for the nodes output file (default: nodes.csv): ").strip() or "nodes.csv"
edges_output = input("Enter the name for the edges output file (default: edges.csv): ").strip() or "edges.csv"

process_csv(input_file, nodes_output, edges_output)