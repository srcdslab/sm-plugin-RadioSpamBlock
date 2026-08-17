# RadioSpamBlock Plugin - Copilot Instructions

## Repository Overview
This repository contains a SourcePawn plugin for SourceMod that prevents radio command spam in Source engine games (Counter-Strike, etc.). The plugin implements time-based restrictions on radio commands and provides admin controls for managing radio access.

## Technical Environment
- **Language**: SourcePawn
- **Platform**: SourceMod 1.12+
- **Build Tool**: Native GitHub Actions (rumblefrog/setup-sp)
- **Compiler**: SourceMod SourcePawn Compiler (spcomp)
- **Dependencies**: MultiColors include library

## Project Structure
```
addons/sourcemod/
├── scripting/
│   └── RadioSpamBlock.sp          # Main plugin source code
└── translations/
    └── radiospamblock.phrases.txt # Localization phrases (EN/RU/FR)
.github/workflows/ci.yml           # CI/CD pipeline
```

## Plugin Architecture

### Core Functionality
- **Radio Spam Prevention**: Time-based cooldown system between radio commands
- **Admin Controls**: Commands to mute/unmute specific players' radio access
- **Global Radio Disable**: Option to disable all radio commands server-wide
- **User Notifications**: Configurable feedback when radio is blocked

### Key Components
1. **UserMessage Hooks**: `RadioText` and `SendAudio` for protobuf message interception
2. **Console Command Registration**: All radio commands (`coverme`, `takepoint`, etc.)
3. **ConVar System**: Configuration through server console variables
4. **Translation Support**: Multi-language phrase system

### Message Flow Architecture
```
Player types radio command (e.g., "coverme")
    ↓
RestrictRadio() function called
    ↓
Checks: Admin muted? → Return Plugin_Handled
        Global disabled? → Return Plugin_Handled  
        Time cooldown? → Return Plugin_Handled
    ↓
Return Plugin_Continue (allow radio)
    ↓
RadioText hook intercepts message (protobuf)
    ↓
SendAudio hook processes audio component
    ↓
Radio message sent to other players
```

### Global Variables
- `g_bBlocked[MAXPLAYERS + 1]`: Admin-muted players
- `g_bRadioLastUse[MAXPLAYERS+1]`: Last radio usage timestamps
- `g_iMessageClient`: Current message sender for hook correlation
- `note[MAXPLAYERS+1]`: Last notification time to prevent spam messages

## Build System

### GitHub Actions Configuration
The project builds directly with spcomp via `rumblefrog/setup-sp`, cloning the
MultiColors include dependency at build time. See `.github/workflows/ci.yml`
for the full pipeline.

### Building Locally
```bash
# Install the SourceMod 1.12.x compiler (spcomp) and the MultiColors include,
# then compile from addons/sourcemod/scripting:
spcomp -i include -o ../plugins/RadioSpamBlock.smx RadioSpamBlock.sp
```

### Build Outputs
- Compiled plugin: `addons/sourcemod/plugins/RadioSpamBlock.smx`
- Translations copied to package during CI

## Code Style & Standards

### SourcePawn Best Practices Applied
- ✅ `#pragma semicolon 1` and `#pragma newdecls required`
- ✅ Global variables prefixed with `g_`
- ✅ PascalCase for functions (`OnPluginStart`, `Command_RadioMute`)
- ✅ camelCase for local variables
- ✅ Proper handle management (INVALID_HANDLE initialization)
- ✅ Translation file usage for user messages
- ✅ Client validation with `IsValidClient()`

### Important SourcePawn Guidelines
- **Memory Management**: Use `delete` directly without null checks (not applicable in this plugin)
- **String Operations**: Avoid in frequently called functions (handled in `RestrictRadio`)
- **SQL Operations**: All SQL must be async (not used in this plugin)
- **Handle Management**: ConVars created once, no dynamic cleanup needed
- **Performance**: Time-based checks are O(1), maintaining server tick rate

### Plugin-Specific Patterns
```sourcepawn
// ConVar pattern
Handle cvar_name = INVALID_HANDLE;
cvar_name = CreateConVar("sm_name", "default", "description", flags, min, max);

// Client array initialization
for (int i = 0; i <= MAXPLAYERS; i++)
    g_bRadioLastUse[i] = -1;

// Target processing for admin commands
ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, 
    COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_IMMUNITY, 
    sTargetName, sizeof(sTargetName), bIsML);
```

## Development Guidelines

### When Modifying Radio Functionality
1. **Always test with protobuf detection**: The plugin handles both protobuf and legacy message systems
2. **Maintain hook correlation**: `g_iMessageClient` links `RadioText` and `SendAudio` hooks
3. **Preserve admin override**: `g_bBlocked` always takes precedence over spam detection

### Adding New Features
1. **Follow existing ConVar pattern**: Create ConVar in `OnPluginStart()`, use consistent naming
2. **Add translations**: All user-facing messages must support localization
3. **Update `OnClientConnected`/`OnClientDisconnect`**: Reset any new per-client state
4. **Consider the build workflow**: Dependencies are cloned in `.github/workflows/ci.yml`

### Memory Management
- ConVars are created once in `OnPluginStart()` and don't need cleanup
- Client arrays are reset on connect/disconnect
- No dynamic memory allocation in this plugin

## Testing Approach

### Manual Testing
1. **Load plugin** on SourceMod test server
2. **Test radio commands** with different time intervals
3. **Verify admin commands** (`sm_radiomute`, `sm_radiounmute`)
4. **Check translations** in different languages
5. **Test edge cases**: rapid reconnection, invalid targets

### Configuration Testing
Test these ConVar combinations:
- `sm_radio_spam_block 0/1` (enable/disable)
- `sm_radio_spam_block_time` (various intervals)
- `sm_radio_spam_block_all 1` (global disable)
- `sm_radio_spam_block_notify 0` (silent mode)

## Common Pitfalls

### SourcePawn-Specific
- **Array bounds**: Always validate client indices (1 to MaxClients)
- **Handle leaks**: Not applicable here (no dynamic handles created)
- **Translation context**: Use `SetGlobalTransTarget(client)` before translated messages

### Plugin-Specific
- **Hook timing**: `RadioText` hook must set `g_iMessageClient` before `SendAudio` hook
- **Sound filtering**: The `strncmp(sSound[6], "lock", 4)` check prevents blocking lock sounds
- **Time synchronization**: Use `GetTime()` consistently for spam detection

## CI/CD Pipeline

### Automated Workflow
1. **Build**: spcomp compilation via `rumblefrog/setup-sp`, with MultiColors cloned as a dependency
2. **Package**: Copy translations and create release structure
3. **Tag**: Auto-tag latest builds from main branch
4. **Release**: Create GitHub releases with packaged plugin

### Artifacts
- `RadioSpamBlock.smx`: Compiled plugin
- `radiospamblock.phrases.txt`: Translation file
- Release tarball includes proper SourceMod directory structure

### Dependency Management
- **Dependabot**: Configured for weekly GitHub Actions updates
- **CI workflow**: Clones the MultiColors include repo during the build step
- **Version Pinning**: SourceMod compiler pinned to the 1.12.x branch via `rumblefrog/setup-sp`

## Dependencies

### Required Includes
- `sourcemod`: Core SourceMod API
- `multicolors`: Enhanced color messaging (external dependency)

### CI Dependency Management
Dependencies are fetched during the build step in `.github/workflows/ci.yml`:
```bash
git clone --depth=1 https://github.com/srcdslab/sm-plugin-MultiColors.git deps/multicolors
cp -R deps/multicolors/addons/sourcemod/scripting/include/* addons/sourcemod/scripting/include/
```

## File Modification Guidelines

### When editing `RadioSpamBlock.sp`
- Maintain existing hook structure
- Preserve client state management patterns
- Keep admin command validation logic
- Update version number in plugin info (currently "1.2.0")

### When editing `radiospamblock.phrases.txt`
- Maintain UTF-8 BOM encoding
- Keep existing language keys (en/ru/fr)
- Follow SourceMod phrase file format
- Test format placeholders (`{1:d}`, etc.)

### When editing `.github/workflows/ci.yml`
- Version changes require testing build compatibility
- New dependencies need proper clone/copy steps added to the Install dependencies step
- Maintain existing project structure

## Versioning Strategy
- **Plugin Version**: Hardcoded in `myinfo` structure in .sp file
- **Git Tags**: Semantic versioning with `latest` tag for development builds
- **Release Automation**: CI creates releases automatically for tags and main branch
- **Version Consistency**: Keep plugin version in sync with Git tags for releases

This plugin serves as a good example of proper SourcePawn development practices with modern build tools.