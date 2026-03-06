using System;
using System.Diagnostics;
using System.Text;
using UnityEngine;

namespace TCFramework
{
    public class CmdRunner : IDisposable
    {
        static Encoding encoding => Encoding.GetEncoding("GB2312");

        Action<string> m_LogError;
        Process m_Process;

        public CmdRunner(Action<string> logError)
        {
            m_LogError = logError;
        }

        public void Run(string cmd)
        {
            if (m_Process == null)
                InitProcess();

            m_Process.StandardInput.WriteLine(cmd);
            m_Process.StandardInput.Flush();
        }

        void InitProcess()
        {
            ProcessStartInfo startInfo = new ProcessStartInfo();
            if (Application.platform == RuntimePlatform.WindowsEditor)
                startInfo.FileName = "cmd";
            else
                startInfo.FileName = "/bin/bash";
            startInfo.UseShellExecute = false;
            startInfo.RedirectStandardInput = true;
            startInfo.RedirectStandardOutput = true;
            startInfo.RedirectStandardError = true;
            startInfo.StandardInputEncoding = encoding;
            startInfo.StandardOutputEncoding = encoding;
            startInfo.StandardErrorEncoding = encoding;
            startInfo.CreateNoWindow = true;

            m_Process = Process.Start(startInfo);

            if (m_LogError != null)
            {
                m_Process.ErrorDataReceived += (sender, args) =>
                {
                    if (!string.IsNullOrEmpty(args.Data))
                        m_LogError(args.Data);
                };
            }
            
            m_Process.BeginErrorReadLine();
            m_Process.BeginOutputReadLine();
        }

        public void Dispose()
        {
            if (m_Process != null)
            {
                m_Process.StandardInput.WriteLine("exit");
                m_Process.StandardInput.Flush();
                m_Process.WaitForExit();
                m_Process.Dispose();
            }
        }
    }
}