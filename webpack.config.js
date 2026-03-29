import path from "path";
import webpack from "webpack";
import CopyPlugin from "copy-webpack-plugin";

import { fileURLToPath } from "url";

import fs from "fs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

let entry = ["./src/client/index.tsx"];

let plugins = [];
let debug = true;

let devtool = debug ? "eval-source-map" : "source-map";

let profiler = debug;

entry.unshift("core-js/stable");

export default (env, argv) => {
  const prod = argv?.mode === "production";
  const haxe = env?.haxe === true || env?.haxe === "true";
  const mode = prod ? "production" : "development";
  const target = "web";

  const archMacroMap = {
    "x86_64": "HXCPP_M64",
    "x86": "HXCPP_M32",
    "arm64": "HXCPP_ARM64",
    "armv7": "HXCPP_ARMV7",
  };

  const arch = env?.arch || "x86_64";
  const hxcppDefine = archMacroMap[arch];

  plugins.push(
    new webpack.DefinePlugin({
      "process.env.NODE_ENV": JSON.stringify(mode),
      PROFILER: JSON.stringify(profiler),
      DEBUG: JSON.stringify(!prod),
      PLATFORM: JSON.stringify("web"),
    }),
  );

  let outputPath = path.resolve(__dirname, "dist");

  if (prod) {
    plugins.push(
      new CopyPlugin({
        patterns: [
          {
            from: "src/client/resources",
            to: haxe ? "assets" : "",
            globOptions: { ignore: ["**/.DS_Store"] },
          },
        ],
      }),
    );
    if (haxe) {
      plugins.push(
        new CopyPlugin({
          patterns: [
            {
               from: "src/haxe",
               to: "",
               globOptions: { ignore: ["**/.DS_Store"] },
            },
          ],
        }),
      );

      const hxmlPath = path.resolve(__dirname, "src/haxe/compile.hxml");
      let hxml = fs.readFileSync(hxmlPath, "utf-8");
      hxml = hxml.replace(/-D\s+HXCPP_(M64|M32|ARM64|ARMV7)/g, "");
      hxml += `\n-D ${hxcppDefine}\n`;
      fs.writeFileSync(hxmlPath, hxml);
    }

    debug = false;
  } else {
    entry.push("webpack-dev-server/client?http://localhost:4000");
    plugins.push(
      new CopyPlugin({
        patterns: [
          {
            from: "src/client/resources",
            to: "",
            globOptions: { ignore: ["**/.DS_Store"] },
          },
        ],
      }),
    );
  }

  const config = {
    entry,
    output: {
      path: outputPath,
      filename: haxe ? "assets/static/js/index.js" : "static/js/index.js",
    },
    devServer: {
      static: "./dist",
    },
    devtool,
    target,
    mode,
    module: {
      noParse: /.*[/\\]bin[/\\].+\.js/,
      rules: [
        {
          test: /\.tsx$/,
          use: [{ loader: "ts-loader" }],
          exclude: /node_modules/,
        },
        {
          test: /\.ts$/,
          use: [{ loader: "ts-loader" }],
          exclude: /node_modules/,
        },
        {
          test: /.jsx?$/,
          include: [path.resolve(__dirname, "src")],
          use: [
            {
              loader: "babel-loader",
              options: {
                presets: ["@babel/preset-react", "@babel/preset-env"],
              },
            },
          ],
        },
        {
          test: /\.js$/,
          include: [path.resolve(__dirname, "src")],
          use: [
            {
              loader: "babel-loader",
              options: { presets: ["@babel/preset-env"] },
            },
          ],
        },
        {
          test: /\.(html|htm)$/,
          use: [{ loader: "dom" }],
        },
        {
          test: /\.mst$/,
          use: [{ loader: "raw-loader" }],
        },
      ],
    },
    optimization: {
      minimize: prod,
      usedExports: true,
    },
    plugins,
  };

  config.resolve = {
    alias: { platform: path.resolve(__dirname, "./src/client/platform/web") },
  };
  config.resolve.alias.api = path.resolve(__dirname, "./src/api");
  config.resolve.alias.client = path.resolve(__dirname, "./src/client");
  config.resolve.alias.TypedObserver = path.resolve(
    __dirname,
    "./src/client/TypedObserver",
  );
  config.resolve.extensions = [".tsx", ".ts", ".jsx", ".js"];

  return config;
};
