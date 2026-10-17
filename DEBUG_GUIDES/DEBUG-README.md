# Custom Connection String

Server=127.0.0.1,14333;Database=nopCommerce;User Id=sa;Password=nopCommerce_db_password;TrustServerCertificate=True;



# Debug nopCommerce in VS Code

This setup runs Nop.Web directly on Windows under the VS Code debugger.
Docker runs SQL Server only.

## 1. Requirements

- Windows x64
- Visual Studio Code
- The Microsoft C# extension for VS Code
- Docker Desktop
- PowerShell

A global .NET installation is not required. This setup uses .NET 9 from the
repository's `.dotnet` directory. Do not change nopCommerce to target .NET 10.

## 2. Local .NET 9 setup

nopCommerce targets `net9.0`. The current setup uses the .NET SDK 9.0.317 x64
and the .NET 9.0.19 runtimes.

The `.dotnet` directory is ignored by Git, so install it after a fresh clone.
From the repository root, run:

```powershell
Invoke-WebRequest https://dot.net/v1/dotnet-install.ps1 -OutFile "$env:TEMP\dotnet-install.ps1"
& "$env:TEMP\dotnet-install.ps1" -Version 9.0.317 -Architecture x64 -InstallDir (Join-Path $PWD '.dotnet')
```

This uses Microsoft's official `dotnet-install.ps1` script. It does not install
.NET globally.

Verify the installation:

```powershell
.\.dotnet\dotnet.exe --info
.\.dotnet\dotnet.exe --list-sdks
.\.dotnet\dotnet.exe --list-runtimes
```

The output must include:

- SDK `9.0.317`
- `Microsoft.NETCore.App 9.0.19`
- `Microsoft.AspNetCore.App 9.0.19`
- Architecture `x64`

## 3. Infrastructure

Start SQL Server manually with:

```powershell
docker compose -f docker-compose.debug.yml up -d
```

Docker starts one service: SQL Server 2019 Express. Its data is kept in a
named Docker volume.

Use these settings from the host:

- Server: `localhost,14333`
- Username: `sa`
- Password: `nopCommerce_db_password`
- Database: `nopCommerce`

Connection string:

```text
Server=localhost,14333;Database=nopCommerce;User Id=sa;Password=nopCommerce_db_password;TrustServerCertificate=True;
```

Nop.Web is not in Docker.

## 4. First-time setup

The first start opens the nopCommerce installation page.

Choose SQL Server and enter the server, database, username, and password shown
above. Allow nopCommerce to create the `nopCommerce` database if it does not
exist. Choose your own administrator email and password, then run the install.

## 5. Debugging

1. Open the repository folder in VS Code.
2. Open a C# file and add a breakpoint.
3. Press **F5**.
4. If asked, select `nopCommerce: Web (host, Development)`.

F5 automatically:

1. Starts Docker Desktop if needed and available at its standard install path.
2. Starts and health-checks SQL Server.
3. Builds `src\NopCommerce.sln` with `.dotnet\dotnet.exe`.
4. Starts Nop.Web with the local .NET 9 host.
5. Attaches the C# debugger.

Open:

```text
http://localhost:5000
```

On the first run, this redirects to:

```text
http://localhost:5000/install
```

## 6. Normal workflow

After the first setup:

1. Open the repository in VS Code.
2. Add breakpoints.
3. Press **F5**.

You do not need to start SQL Server first. The F5 pre-launch task starts it and
waits until it is healthy.

## 7. Useful commands

Start SQL Server:

```powershell
docker compose -f docker-compose.debug.yml up -d
```

Stop SQL Server:

```powershell
docker compose -f docker-compose.debug.yml down
```

Check local .NET:

```powershell
.\.dotnet\dotnet.exe --info
```

## 8. Troubleshooting

### Error `0x80008096`

nopCommerce targets .NET 9. A global .NET 10 runtime alone cannot run it.
The error occurred when the debugger used `C:\Program Files\dotnet` instead of
the repository-local .NET 9 runtime.

The current `.vscode\launch.json` fixes this by launching:

```text
<repository>\.dotnet\dotnet.exe
```

Do not change the debug program back to only `Nop.Web.dll`. VS Code must not
fall back to `C:\Program Files\dotnet`.

### VS Code looks for `<workspace>\powershell.exe`

The infrastructure task now uses the full Windows PowerShell path:

```text
C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
```

Keep this value in `.vscode\tasks.json`.

## 9. Architecture

```text
VS Code
|
+-- nopCommerce source
+-- local .NET 9
+-- debugger / breakpoints
|
+-- Docker
    +-- SQL Server
```

Nop.Web runs on the host. It does not run inside Docker.

## 10. Verification

This setup was verified with the current repository:

- Local .NET SDK 9.0.317 x64 was detected.
- .NET and ASP.NET Core runtimes 9.0.19 were detected.
- The solution built successfully with the local SDK.
- The debugger used `.dotnet\dotnet.exe` and loaded Nop.Web symbols.
- A C# source breakpoint bound and was reached.
- `http://localhost:5000/install` returned HTTP 200.
- The SQL Server container became healthy.
- No application source code was changed for this setup.
