using System;
using System.Diagnostics;
using Microsoft.Framework.Runtime;
using Microsoft.Framework.Runtime.Common.CommandLine;

namespace HelloK {
    public class Program {
        private readonly IApplicationEnvironment _env;
        public Program(IApplicationEnvironment env) {
            _env = env;
        }

        public int Main(string[] args) {
            var art =
                "\x1b[33m   ___   _______  \x1b[34m  _  ____________" + Environment.NewLine +
                "\x1b[33m  / _ | / __/ _ \\ \x1b[34m / |/ / __/_  __/" + Environment.NewLine +
                "\x1b[33m / __ |_\\ \\/ ___/ \x1b[34m/    / _/  / /   " + Environment.NewLine +
                "\x1b[33m/_/ |_/___/_/  \x1b[37m(_)\x1b[34m_/|_/___/ /_/    \x1b[39m";

            AnsiConsole.Output.WriteLine(art);
            AnsiConsole.Output.WriteLine("Runtime is sane!");
            AnsiConsole.Output.WriteLine("\x1b[30mRuntime Framework:    \x1b[39m " + _env.RuntimeFramework.ToString());
#if ASPNETCORE50
            AnsiConsole.Output.WriteLine("\x1b[30mRuntime:              \x1b[39m Microsoft CoreCLR");
#else
            // Platform detection
            var platform = GetPlatform();

            AnsiConsole.Output.WriteLine("\x1b[30mRuntime:              \x1b[39m " + (Type.GetType("Mono.Runtime") != null ? "Mono CLR" : "Microsoft CLR"));
            AnsiConsole.Output.WriteLine("\x1b[30mRuntime Version:      \x1b[39m " + Environment.Version.ToString());
            AnsiConsole.Output.WriteLine("\x1b[30mOS:                   \x1b[39m " + platform);
            AnsiConsole.Output.WriteLine("\x1b[30mMachine Name:         \x1b[39m " + Environment.MachineName ?? "<null>");
            AnsiConsole.Output.WriteLine("\x1b[30mUser Name:            \x1b[39m " + Environment.UserName ?? "<null>");
            AnsiConsole.Output.WriteLine("\x1b[30mSystem Directory:     \x1b[39m " + Environment.SystemDirectory ?? "<null>");
            AnsiConsole.Output.WriteLine("\x1b[30mCurrent Directory:    \x1b[39m " + Environment.CurrentDirectory ?? "<null>");
#endif
            AnsiConsole.Output.WriteLine("");
            AnsiConsole.Output.WriteLine(
                "\x1b[1m" +
                "\x1b[30mA" + 
                "\x1b[31mN" + 
                "\x1b[32mS" +
                "\x1b[33mI" + " " +
                "\x1b[34mR" +
                "\x1b[35ma" +
                "\x1b[36mi" +
                "\x1b[37mn" +
                "\x1b[38mb" +
                "\x1b[22m" +
                "\x1b[30mo" +
                "\x1b[32mw" +
                "\x1b[33m!" +
                "\x1b[34m!" +
                "\x1b[35m!" +
                "\x1b[36m!" +
                "\x1b[37m!" +
                "\x1b[38m!" +
                "\x1b[39m");

            return 0;
        }

        private string GetUnameValue(string arg) {
            var psi = new ProcessStartInfo("uname", "-" + arg);
            psi.UseShellExecute = false;
            psi.RedirectStandardOutput = true;
            var p = Process.Start(psi);
            var ret = p.StandardOutput.ReadToEnd().Trim();
            p.WaitForExit();
            return ret;
        }

        private string GetSwVersValue(string arg) {
            var psi = new ProcessStartInfo("sw_vers", "-" + arg);
            psi.UseShellExecute = false;
            psi.RedirectStandardOutput = true;
            var p = Process.Start(psi);
            var ret = p.StandardOutput.ReadToEnd().Trim();
            p.WaitForExit();
            return ret;
        }

#if !ASPNETCORE50
        private string GetPlatform() {
            if(Environment.OSVersion.Platform == PlatformID.Unix) {
                var kern = GetUnameValue("s");
                var kernVer = GetUnameValue("r");
                if(string.Equals(kern, "Darwin", StringComparison.OrdinalIgnoreCase)) {
                    var name = GetSwVersValue("productName");
                    var ver = GetSwVersValue("productVersion");
                    var build = GetSwVersValue("buildVersion");
                    return name + " " + ver + " Build " + build + " (" + kern + " " + kernVer + ")";
                } else {
                    return kern + " " + kernVer;
                }
            } else {
                return Environment.OSVersion.VersionString;
            }
        }
#endif
       
    }
}