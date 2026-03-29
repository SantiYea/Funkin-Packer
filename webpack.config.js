import path from "path";
import webpack from "webpack";
import CopyPlugin from "copy-webpack-plugin";

import { fileURLToPath } from "url";

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
  const mode = prod ? "production" : "development";
  const target = "web";

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
    outputPath = path.resolve(__dirname, "web");

    plugins.push(
      new CopyPlugin({
        patterns: [
          {
            from: "src/client/resources",
            to: "",
            globOptions: { ignore: ["**/.DS_Store"] },
          },
          {
            from: "src/package.json",
            to: "package.json",
          },
        ],
      }),
    );

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
      filename: "static/js/index.js",
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
