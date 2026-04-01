# Temp Directory

This directory contains all EDA tool temporary files and simulation outputs.

**IMPORTANT:** This directory is .gitignore'd and should NOT be committed to the repository.

## Structure

| Directory | Purpose |
|-----------|---------|
| VCS/ | VCS/Xcelium simulation outputs, VCD files, logs |
| Verdi/ | Verdi debug database, waveforms |
| Spyglass/ | Spyglass Lint/CDC reports |
| Coverage/ | Coverage data and HTML reports |
| Others/ | Other tool temporary files |

## Generated Files

- `*.vcd` - Value Change Dump (waveform files)
- `*.log` - Simulation logs
- `simv` - Compiled simulation executable
- Coverage database files

## Cleanup

To clean all temporary files:

```bash
make clean          # From Database/Verification/
# or
rm -rf Temp/VCS/* Temp/Coverage/*
```
