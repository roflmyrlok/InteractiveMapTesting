# Data Acquisition Project

This project is for acquiring, transforming, and exporting location data from various sources.

## Project Structure

```
DataAcquisition/
├── src/
│   ├── DataAcquisition.Core/       # Core interfaces and models
│   ├── DataAcquisition.Kyiv/       # Kyiv-specific implementation
│   ├── DataAcquisition.Cli/        # Command-line interface
│   └── DataAcquisition.Tests/      # Unit tests
├── data/                           # Raw data sources
└── README.md
```

## Features

- Fetch location data from various city-specific sources
- Transform data to a standardized format
- Export data to files or APIs
- Extensible architecture for supporting additional cities
- Command-line interface for import/export operations

## Adding Support for a New City

To add support for data from another city:

1. Create a new project (e.g., `DataAcquisition.NewCity`)
2. Implement city-specific models and services
3. Add a reference to the Core project
4. Update the CLI to support the new city
