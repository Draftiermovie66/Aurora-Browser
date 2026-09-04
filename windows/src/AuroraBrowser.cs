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
            if (Directory.Exists(extensionDir))
                psi.ArgumentList.Add("--load-extension=" + extensionDir);

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