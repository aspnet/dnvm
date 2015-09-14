using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Dnx.Runtime;
using Microsoft.Dnx.Runtime.Common.CommandLine;

namespace Microsoft.Dnx.VersionManager
{
    public class Program
    {
        public Program(IRuntimeEnvironment env)
        {
        }

        public int Main(string[] args)
        {
            try
            {
                var app = new CommandLineApplication();
                app.Name = "dnvm";
                app.Description = "DNVM can be used to download versions of the .NET Execution Environment and manage which version you are using.";

                app.HelpOption("-?|-h|--help");

                app.Command("alias", c =>
                {
                    c.Description = "Lists and manages aliases";

                    var aliasName = c.Argument("name", "The name of the alias to read/create/delete");
                    c.Argument("version", "The version to assign to the new alias");

                    var delete = c.Option("--delete", "Set this switch to delete the alias with the specified name", CommandOptionType.NoValue);
                    var arch = c.Option("--arch", "The architecture of the runtime to assign to this alias", CommandOptionType.SingleValue);
                    var runtime = c.Option("--runtime", "The flavor of the runtime to assign to this alias", CommandOptionType.SingleValue);

                    c.HelpOption("-?|-h|--help");

                    c.OnExecute(() =>
                    {
                        c.ShowRootCommandFullNameAndVersion();

                        if(delete.HasValue())
                        {
                            foreach(var runtimeHome in DnxSdk.GetRuntimeHomes())
                            {
                                DnxAlias.Delete(runtimeHome, aliasName.Value);
                            }
                        }

                        return 0;
                    });
                });

                app.Command("exec", c =>
                {
                    c.Description = "Executes the specified command in a sub-shell where the PATH has been augmented to include the specified DNX";
                });

                app.Command("install", c =>
                {
                    c.Description = "Installs a version of the runtime";

                    c.Argument("VersionNuPkgOrAlias", "The version to install from the current channel, the path to a '.nupkg' file to install, 'latest' to install the latest available version from the current channel, or an alias value to install an alternate runtime or architecture flavor of the specified alias.");

                    c.Option("--arch", "The processor architecture of the runtime to install (default: x86)", CommandOptionType.SingleValue);
                    c.Option("--runtime", "The runtime flavor to install (default: clr)", CommandOptionType.SingleValue);
                    c.Option("--alias", "Set alias <Alias> to the installed runtime", CommandOptionType.SingleValue);
                    c.Option("--force", "Overwrite an existing runtime if it already exists", CommandOptionType.NoValue);
                    c.Option("--proxy", "Use the given address as a proxy when accessing remote server", CommandOptionType.SingleValue);
                    c.Option("--no-native", "Skip generation of native images", CommandOptionType.NoValue);
                    c.Option("--ngen", "For CLR flavor only. Generate native images for runtime libraries on Desktop CLR to improve startup time.This option requires elevated privilege and will be automatically turned on if the script is running in administrative mode. To opt-out in administrative mode, use -NoNative switch.", CommandOptionType.SingleValue);
                    c.Option("--persistent", "Make the installed runtime useable across all processes run by the current user", CommandOptionType.NoValue);
                    c.Option("--unstable", "Upgrade from our unstable dev feed. This will give you the latest development version of the runtime.", CommandOptionType.NoValue);

                    c.HelpOption("-?|-h|--help");

                    c.OnExecute(() =>
                    {
                        return 0;
                    });
                });

                app.Command("list", c =>
                {
                    c.Description = "Lists available runtimes";
                });

                app.Command("run", c =>
                {
                    c.Description = "locates the dnx.exe for the specified version or alias and executes it, providing the remaining arguments to dnx.exe";
                });

                app.Command("setup", c =>
                {
                    c.Description = "Installs the version manager into your User profile directory";
                });

                app.Command("update-self", c =>
                {
                    c.Description = "Updates DNVM to the latest version.";
                });

                app.Command("upgrade", c =>
                {
                    c.Description = "Installs the latest version of the runtime and reassigns the specified alias to point at it.";

                    c.Argument("Alias", "The alias to upgrade (default: 'default')");

                    c.Option("--arch", "The processor architecture of the runtime to install (default: x86)", CommandOptionType.SingleValue);
                    c.Option("--runtime", "The runtime flavor to install (default: clr)", CommandOptionType.SingleValue);
                    c.Option("--force", "Overwrite an existing runtime if it already exists", CommandOptionType.NoValue);
                    c.Option("--proxy", "Use the given address as a proxy when accessing remote server", CommandOptionType.SingleValue);
                    c.Option("--no-native", "Skip generation of native images", CommandOptionType.NoValue);
                    c.Option("--ngen", "For CLR flavor only. Generate native images for runtime libraries on Desktop CLR to improve startup time.This option requires elevated privilege and will be automatically turned on if the script is running in administrative mode. To opt-out in administrative mode, use -NoNative switch.", CommandOptionType.SingleValue);
                    c.Option("--unstable", "Upgrade from our unstable dev feed. This will give you the latest development version of the runtime.", CommandOptionType.NoValue);


                    c.HelpOption("-?|-h|--help");

                    c.OnExecute(() =>
                    {
                        return 0;
                    });
                });

                app.Command("use", c =>
                {
                    c.Description = "Adds a runtime to the PATH environment variable for your current shell.";

                    c.Argument("VersionOrAlias", "The version or alias of the runtime to place on the PATH");

                    c.Option("--arch", "The processor architecture of the runtime to place on the PATH (default: x86, or whatever the alias specifies in the case of use-ing an alias)", CommandOptionType.SingleValue);
                    c.Option("--runtime", "The runtime flavor of the runtime to place on the PATH (default: clr, or whatever the alias specifies in the case of use-ing an alias)", CommandOptionType.SingleValue);
                    c.Option("--persistent", "Make the change persistent across all processes run by the current user", CommandOptionType.NoValue);

                    c.HelpOption("-?|-h|--help");

                    c.OnExecute(() =>
                    {
                        return 0;
                    });
                });

                app.OnExecute(() =>
                {
                    app.ShowHelp();
                    return 2;
                });


                return app.Execute(args);
            }
            catch
            {
                return 1;
            }
        }
    }
}
