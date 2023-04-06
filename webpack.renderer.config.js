const path = require('path');
const webpack = require('webpack');
const CopyPlugin = require('copy-webpack-plugin');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');

module.exports = {
  // target: 'electron-renderer', // do not set,
  // causes "require is not defined" in electron-webpack-plugin
  entry: { renderer: './src/renderer/app.jsx' },
  mode: process.env.production ? 'production' : 'development',
  devtool: 'source-map',
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/,
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
        },
      },
      {
        test: /\.css$/,
        use: [MiniCssExtractPlugin.loader, 'css-loader'],
      },
    ],
  },
  experiments: {
    syncWebAssembly: true,
  },
  plugins: [
    new webpack.DefinePlugin({
      __BUILD_MODE__: JSON.stringify('electron'),
    }),

    new MiniCssExtractPlugin({
      filename: 'style.css',
    }),

    new CopyPlugin({
      patterns: [
        { context: 'src/main/', from: 'preload.js', to: 'public/[name][ext]' },
        { context: 'public/', from: 'icon.png', to: 'public/[name][ext]' },
      ],
    }),
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src/renderer'),
      api: path.resolve(__dirname, './src/api'),
    },
    extensions: ['.js', '.jsx', '.css'],
  },
};
