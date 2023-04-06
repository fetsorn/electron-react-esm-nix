import path from 'path';
import url from 'url';
import webpack from 'webpack';
import MiniCssExtractPlugin from 'mini-css-extract-plugin';
import HtmlWebpackPlugin from 'html-webpack-plugin';

const dirname = path.dirname(url.fileURLToPath(import.meta.url));

export default (env) => ({
  entry: './src/renderer/app.jsx',
  mode: process.env.production ? 'production' : 'development',
  devtool: 'source-map',
  output: {
    path: path.resolve(dirname, 'release/renderer'),
    filename: '[name].bundle.js',
  },
  module: {
    rules: [
      {
        test: /\.(jsx)$/,
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
  plugins: [
    new webpack.DefinePlugin({
      __BUILD_MODE__: JSON.stringify(env.buildMode),
    }),

    new MiniCssExtractPlugin({
      filename: 'style.css',
    }),

    new HtmlWebpackPlugin({
      template: './src/renderer/index.html',
      favicon: './public/favicon.ico',
    }),
  ],
  resolve: {
    alias: {
      '@': path.resolve(dirname, './src/renderer'),
      api: path.resolve(dirname, './src/api'),
    },
    extensions: ['.js', '.jsx', '.css'],
  },
});
