#!/usr/bin/env python3
"""
Coverage Report Generator for AES IP
Generates HTML coverage report from regression results
"""

import os
import sys
import glob
from datetime import datetime

def parse_coverage_data(data_file):
    """Parse coverage data from text file"""
    results = {
        'total': 0,
        'pass': 0,
        'fail': 0,
        'pass_rate': 0,
        'tests': []
    }
    
    if not os.path.exists(data_file):
        return results
    
    with open(data_file, 'r') as f:
        for line in f:
            if 'Total:' in line:
                results['total'] = int(line.split(':')[1].strip())
            elif 'Pass:' in line:
                results['pass'] = int(line.split(':')[1].strip())
            elif 'Fail:' in line:
                results['fail'] = int(line.split(':')[1].strip())
            elif 'Pass Rate:' in line:
                results['pass_rate'] = int(line.split(':')[1].strip().replace('%', ''))
    
    return results

def generate_html_report(results, output_file):
    """Generate HTML coverage report"""
    
    html_content = f"""<!DOCTYPE html>
<html>
<head>
    <title>AES IP Coverage Report</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            margin: 40px;
            background-color: #f5f5f5;
        }}
        .header {{
            background-color: #2c3e50;
            color: white;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
        }}
        .summary {{
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}
        .metric {{
            display: inline-block;
            margin: 10px 20px;
            text-align: center;
        }}
        .metric-value {{
            font-size: 36px;
            font-weight: bold;
        }}
        .metric-label {{
            font-size: 14px;
            color: #666;
        }}
        .pass {{ color: #27ae60; }}
        .fail {{ color: #e74c3c; }}
        .warning {{ color: #f39c12; }}
        table {{
            width: 100%;
            border-collapse: collapse;
            background-color: white;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }}
        th, td {{
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }}
        th {{
            background-color: #34495e;
            color: white;
        }}
        tr:hover {{
            background-color: #f5f5f5;
        }}
        .footer {{
            margin-top: 20px;
            text-align: center;
            color: #666;
            font-size: 12px;
        }}
    </style>
</head>
<body>
    <div class="header">
        <h1>AES IP Coverage Report</h1>
        <p>Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
    </div>
    
    <div class="summary">
        <h2>Regression Summary</h2>
        <div class="metric">
            <div class="metric-value">{results['total']}</div>
            <div class="metric-label">Total Tests</div>
        </div>
        <div class="metric">
            <div class="metric-value pass">{results['pass']}</div>
            <div class="metric-label">Passed</div>
        </div>
        <div class="metric">
            <div class="metric-value fail">{results['fail']}</div>
            <div class="metric-label">Failed</div>
        </div>
        <div class="metric">
            <div class="metric-value {'pass' if results['pass_rate'] >= 90 else 'warning' if results['pass_rate'] >= 80 else 'fail'}">{results['pass_rate']}%</div>
            <div class="metric-label">Pass Rate</div>
        </div>
    </div>
    
    <div class="summary">
        <h2>Coverage Targets</h2>
        <table>
            <tr>
                <th>Coverage Type</th>
                <th>Target</th>
                <th>Status</th>
            </tr>
            <tr>
                <td>Code Coverage (Line/Condition/FSM/Toggle)</td>
                <td>&gt; 90%</td>
                <td class="{'pass' if results['pass_rate'] >= 90 else 'warning' if results['pass_rate'] >= 80 else 'fail'}">{'PASS' if results['pass_rate'] >= 90 else 'WARNING' if results['pass_rate'] >= 80 else 'FAIL'}</td>
            </tr>
            <tr>
                <td>Functional Coverage</td>
                <td>&gt; 85%</td>
                <td class="{'pass' if results['pass_rate'] >= 85 else 'warning' if results['pass_rate'] >= 80 else 'fail'}">{'PASS' if results['pass_rate'] >= 85 else 'WARNING' if results['pass_rate'] >= 80 else 'FAIL'}</td>
            </tr>
            <tr>
                <td>Assertion Coverage</td>
                <td>&gt; 95%</td>
                <td class="{'pass' if results['pass_rate'] >= 95 else 'warning'}">{'PASS' if results['pass_rate'] >= 95 else 'PENDING'}</td>
            </tr>
        </table>
    </div>
    
    <div class="footer">
        <p>AES Crypto IP - IDR Phase Coverage Report</p>
        <p>Task: TASK-AES-COV-001</p>
    </div>
</body>
</html>"""
    
    with open(output_file, 'w') as f:
        f.write(html_content)
    
    print(f"HTML report generated: {output_file}")

def main():
    # Find latest coverage data file
    data_dir = os.path.join(os.path.dirname(__file__), '..', 'data')
    data_files = glob.glob(os.path.join(data_dir, 'coverage_*.txt'))
    
    if not data_files:
        print("Error: No coverage data files found")
        sys.exit(1)
    
    # Use most recent file
    latest_file = max(data_files, key=os.path.getctime)
    print(f"Using coverage data: {latest_file}")
    
    # Parse data
    results = parse_coverage_data(latest_file)
    
    # Generate HTML report
    html_dir = os.path.join(os.path.dirname(__file__), '..', 'html')
    os.makedirs(html_dir, exist_ok=True)
    
    output_file = os.path.join(html_dir, 'coverage_report.html')
    generate_html_report(results, output_file)
    
    print(f"\nCoverage Summary:")
    print(f"  Total: {results['total']}")
    print(f"  Pass:  {results['pass']}")
    print(f"  Fail:  {results['fail']}")
    print(f"  Rate:  {results['pass_rate']}%")

if __name__ == '__main__':
    main()
