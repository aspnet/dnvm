using System;
using System.Diagnostics;
using Microsoft.Framework.Runtime;
using Microsoft.Framework.Runtime.Common.CommandLine;

namespace TestApp {
    public class Program {
        private readonly IApplicationEnvironment _env;
        public Program(IApplicationEnvironment env) {
            _env = env;
        }

        public int Main(string[] args) {
            AnsiConsole.Output.WriteLine("Runtime is sane!");
            return 0;
        } 
    }
}
