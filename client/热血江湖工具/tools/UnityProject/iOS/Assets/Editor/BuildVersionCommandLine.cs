using System;

public class BuildVersionCommandLine
{
    // 命令行参数：
    // -inputDir：输入原始资源目录。
    // -outputDir：输出打包后的资源目录。
    // -rebuild：是否重新打包资源。
    // -fastMode: 快速模式，只打包有变动资源。只能测试使用，正式发包不要用。
    // -removeRes：打包完移除工程内的资源，建议开启，防止工程内资源增多影响打包效率。
    public static void BuildRes()
    {
        string inputDir = null;
        string outputDir = null;
        bool rebuild = false;
        bool fastMode = false;
        bool removeRes = false;
        bool includeModel = false;

        var commandLineArgs = Environment.GetCommandLineArgs();
        int count = commandLineArgs.Length;
        for (int i = 0; i < count; ++i)
        {
            switch (commandLineArgs[i])
            {
                case "-inputDir":
                    if (i + 1 < count)
                    {
                        inputDir = commandLineArgs[++i];
                    }
                    break;
                case "-outputDir":
                    if (i + 1 < count)
                    {
                        outputDir = commandLineArgs[++i];
                    }
                    break;
                case "-rebuild":
                    rebuild = true;
                    break;
                case "-fastMode":
                    fastMode = true;
                    break;
                case "-removeRes":
                    removeRes = true;
                    break;
                case "-includeModel":
                    includeModel = true;
                    break;
            }
        }

        BuildVerison.BuildRes(inputDir, outputDir, rebuild, fastMode, removeRes, includeModel);
    }
}
