using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Microsoft.Dnx.VersionManager
{
    public class DnxSdk
    {
        public string Version { get; set; }

        public string Flavor { get; set; }

        public string Architecture { get; set; }

        public string OperationSystem { get; set; }

        public string Location { get; set; }

        public string FullName { get; set; }

        public static string GetRuntimeHome()
        {
            var homePath = Environment.ExpandEnvironmentVariables(Environment.GetEnvironmentVariable("DNX_HOME"));

            if (string.IsNullOrEmpty(homePath))
            {
                var basePath = Environment.GetEnvironmentVariable("HOME");
                if (string.IsNullOrEmpty(basePath))
                {
                    basePath = Environment.GetEnvironmentVariable("USERPROFILE");
                }

                homePath = Path.Combine(basePath, ".dnx");
            }

            return homePath;
        }

        public static DnxSdk GetRuntime(string fullName)
        {
            string flavor;
            string os;
            string arch;
            string version;
            if (!TryParseFullName(fullName, out flavor, out os, out arch, out version))
            {
                return null;
            }

            return GetRuntime(version, flavor, os, arch);
        }

        public static DnxSdk GetRuntime(string version, string flavor, string os, string arch)
        {
            return GetRuntime(GetRuntimeHome(), version, flavor, os, arch);
        }

        public static DnxSdk GetRuntime(string basePath, string version, string flavor, string os, string arch)
        {
            var fullName = GetRuntimeName(flavor, os, arch) + $".{version}";
            return new DnxSdk
            {
                FullName = fullName,
                Location = Path.Combine(basePath, "runtimes", fullName),
                Architecture = arch,
                Flavor = flavor,
                OperationSystem = os,
                Version = version
            };
        }

        private static bool TryParseFullName(string fullName, out string flavor, out string os, out string arch, out string version)
        {
            flavor = null;
            os = null;
            arch = null;
            version = null;

            var tokenBuilder = new StringBuilder();

            // e.g. dnx-clr-win-x64.1.0.0-dev
            // e.g dnx-mono.1.0.0-dev
            var state = DnxNameState.Dnx;
            foreach (var ch in fullName)
            {
                if (ch == '-')
                {
                    if (state == DnxNameState.Dnx)
                    {
                        var runtime = tokenBuilder.ToString();

                        if (!string.Equals(runtime, "dnx", StringComparison.OrdinalIgnoreCase))
                        {
                            return false;
                        }

                        state = DnxNameState.Flavor;
                        tokenBuilder.Clear();
                    }
                    else if (state == DnxNameState.Flavor)
                    {
                        flavor = tokenBuilder.ToString();

                        if (!IsValidFlavor(flavor))
                        {
                            return false;
                        }

                        state = DnxNameState.Os;
                        tokenBuilder.Clear();
                    }
                    else if (state == DnxNameState.Os)
                    {
                        os = tokenBuilder.ToString();

                        if (!IsValidOS(os))
                        {
                            return false;
                        }

                        state = DnxNameState.Arch;
                        tokenBuilder.Clear();
                    }
                    else
                    {
                        tokenBuilder.Append(ch);
                    }
                }
                else if (ch == '.')
                {
                    if (state == DnxNameState.Arch)
                    {
                        arch = tokenBuilder.ToString();

                        if (!IsValidArch(arch))
                        {
                            return false;
                        }

                        state = DnxNameState.Version;
                        tokenBuilder.Clear();

                        continue;
                    }
                    else if (state == DnxNameState.Flavor)
                    {
                        flavor = tokenBuilder.ToString();

                        if (string.Equals(flavor, "mono", StringComparison.OrdinalIgnoreCase))
                        {
                            state = DnxNameState.Version;
                            tokenBuilder.Clear();

                            continue;
                        }
                    }

                    tokenBuilder.Append(ch);
                }
                else
                {
                    tokenBuilder.Append(ch);
                }
            }

            if (state != DnxNameState.Version)
            {
                return false;
            }

            version = tokenBuilder.ToString();

            return true;
        }

        private static bool IsValidFlavor(string flavor)
        {
            switch (flavor.ToLowerInvariant())
            {
                case "mono":
                case "clr":
                case "coreclr":
                    return true;
            }
            return false;
        }

        private static bool IsValidArch(string arch)
        {
            switch (arch.ToLowerInvariant())
            {
                case "arm":
                case "x86":
                case "x64":
                    return true;
            }
            return false;
        }

        private static bool IsValidOS(string os)
        {
            switch (os.ToLowerInvariant())
            {
                case "linux":
                case "darwin":
                case "win":
                    return true;
            }
            return false;
        }

        private static string GetRuntimeName(string flavor, string os, string architecture)
        {
            // Mono ignores os and architecture
            if (string.Equals(flavor, "mono", StringComparison.OrdinalIgnoreCase))
            {
                return "dnx-mono";
            }

            return $"dnx-{flavor}-{os}-{architecture}";
        }

        private enum DnxNameState
        {
            Dnx,
            Flavor,
            Os,
            Arch,
            Version
        }
    }
}
