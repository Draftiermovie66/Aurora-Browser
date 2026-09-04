using System;
using System.Diagnostics;
using System.IO;

namespace AuroraBrowser
{
    class Program
    {
        static int Main(string[] args)
        {
            string dir = AppDomain.CurrentDomain.BaseDirectory.TrimEnd('\\', '/');

            string updateCheck = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.UserProfile),
                ".aurora", "last-update-check");

            string updatePs1 = Path.Combine(dir, "update.ps1");
            string chromeExe = Path.Combine(dir, "chrome-win", "chrome.exe");
            string profileDir = Path.Combine(dir, "profile");
            string extensionDir = Path.Combine(dir, "extension");
            string versionFile = Path.Combine(dir, "version.txt");

            string engineVer = "152.0.0.0";
            try
            {
                if (File.Exists(versionFile))
                {
                    foreach (string line in File.ReadAllLines(versionFile))
                    {
                        if (line.StartsWith("CHROMIUM_VERSION="))
                        {
                            engineVer = line.Substring("CHROMIUM_VERSION=".Length).Trim();
                            break;
                        }
                    }
                }
            }
            catch (Exception) { }
            if (string.IsNullOrWhiteSpace(engineVer)) engineVer = "152.0.0.0";
            string majorVer = engineVer.Contains(".") ? engineVer.Substring(0, engineVer.IndexOf('.')) : engineVer;
            string ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/" + engineVer + " Safari/537.36 AuroraBrowser/" + majorVer;

            if (!File.Exists(updateCheck))
            {
                Directory.CreateDirectory(Path.GetDirectoryName(updateCheck));
                File.WriteAllText(updateCheck, "1");
                if (File.Exists(updatePs1))
                {
                    Process.Start(new ProcessStartInfo("powershell.exe")
                    {
                        UseShellExecute = true,
                        WindowStyle = ProcessWindowStyle.Hidden,
                        Arguments = "-NoProfile -ExecutionPolicy Bypass -File \"" + updatePs1 + "\" -quiet"
                    });
                }
            }

            if (!File.Exists(chromeExe))
            {
                Console.Error.WriteLine("Aurora Browser: chrome-win\\chrome.exe not found.");
                Console.Error.WriteLine("Run update.ps1 to download Chromium first.");
                if (Environment.UserInteractive) { Console.ReadKey(true); }
                return 1;
            }

            var psi = new ProcessStartInfo(chromeExe)
            {
                UseShellExecute = false,
                WorkingDirectory = dir
            };

            psi.ArgumentList.Add("--user-data-dir=" + profileDir);
            psi.ArgumentList.Add("--no-first-run");
            psi.ArgumentList.Add("--disable-features=TranslateUI");
            psi.ArgumentList.Add("--disable-background-networking");
            psi.ArgumentList.Add("--disable-component-update");
            psi.ArgumentList.Add("--user-agent=" + ua);
            if (Directory.Exists(extensionDir))
                psi.ArgumentList.Add("--load-extension=" + extensionDir);

            if (args.Length == 0)
                psi.ArgumentList.Add("chrome://newtab");

            foreach (string a in args)
                psi.ArgumentList.Add(a);

            try
            {
                using (Process p = Process.Start(psi))
                    return 0;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine("Failed to launch Aurora Browser: " + ex.Message);
                if (Environment.UserInteractive) { Console.ReadKey(true); }
                return 1;
            }
        }
    }
}