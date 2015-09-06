using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Dnx.Runtime.Common.CommandLine;

namespace Microsoft.Dnx.VersionManager
{
    public class Program
    {
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
                });

                app.Command("exec", c =>
                {
                    c.Description = "Executes the specified command in a sub-shell where the PATH has been augmented to include the specified DNX";
                });

                app.Command("install", c =>
                {
                    c.Description = "Installs a version of the runtime";
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
                });

                app.Command("use", c =>
                {
                    c.Description = "Adds a runtime to the PATH environment variable for your current shell.";
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
