# R Backend Setup Guide

## Prerequisites

### Install R

#### Windows
1. Download R from https://cran.r-project.org/bin/windows/base/
2. Run the installer and follow the setup wizard
3. Add R to your system PATH (usually done automatically)
4. Verify installation by opening Command Prompt and running: `Rscript --version`

#### macOS
```bash
# Using Homebrew (recommended)
brew install r

# Or download from https://cran.r-project.org/bin/macosx/
```

#### Linux (Ubuntu/Debian)
```bash
sudo apt update
sudo apt install r-base r-base-dev
```

#### Linux (CentOS/RHEL)
```bash
sudo yum install R
```

### Verify R Installation

Open a terminal/command prompt and run:
```bash
Rscript --version
```

You should see output similar to:
```
R scripting front-end version 4.x.x (2024-xx-xx)
```

## Setup Steps

### 1. Install Required R Packages

Navigate to the `r-backend` directory and run:

**Windows:**
```cmd
cd r-backend
Rscript install-packages.R
```

**macOS/Linux:**
```bash
cd r-backend
Rscript install-packages.R
```

### 2. Start the R API Server

**Windows:**
```cmd
start-server.bat
# Or with custom port:
start-server.bat 8002
```

**macOS/Linux:**
```bash
chmod +x start-server.sh
./start-server.sh
# Or with custom port:
./start-server.sh 8002
```

### 3. Test the Server

Once the server is running, test it:

```bash
curl http://localhost:8001/health
```

Or open in browser: http://localhost:8001/health

## Troubleshooting

### R Not Found
- Ensure R is installed and added to your system PATH
- On Windows, you may need to restart your terminal after installation
- Try running `R --version` to verify R installation

### Package Installation Fails
- Ensure you have internet connection for CRAN access
- On Linux, you may need `r-base-dev` for package compilation
- Try running R interactively and installing packages manually:
  ```r
  install.packages(c("plumber", "data.table", "jsonlite"))
  ```

### Port Already in Use
- Use a different port: `./start-server.sh 8002`
- Check what's using port 8001: `netstat -an | grep 8001`

### Permission Errors
- On macOS/Linux, make scripts executable: `chmod +x *.sh`
- Ensure you have write permissions in the R library directory

## Development Notes

- The server runs on `127.0.0.1:8001` by default
- CORS is enabled for frontend integration
- The server includes automatic package version reporting
- Health check endpoint provides system status information