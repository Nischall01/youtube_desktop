# YouTube Desktop

A professional Windows desktop application built with Flutter that provides an integrated YouTube browsing experience with powerful downloading capabilities.

## Features

-   **Integrated WebView:** Browse YouTube directly within the application using a native Windows WebView.
-   **Video Downloader:** Download YouTube videos in high quality (up to 4K/8K where supported) using `yt-dlp`.
-   **Audio Extractor:** One-click audio extraction to high-quality format (MP3/Opus).
-   **Album Maker:** Specialized tools for organizing downloaded tracks with custom metadata and album art (In Development).
-   **Authentication Support:** Integrated support for `cookies.txt` to download age-restricted or private content.
-   **Real-time Progress:** Live download progress tracking with percentage and status updates.
-   **Dark Mode UI:** Sleek, modern interface designed for desktop use.

## Prerequisites

To use the downloading features, you must have `yt-dlp` installed on your system:

-   **Windows:** 
    ```bash
    winget install yt-dlp
    ```
    Or download the executable from the [official repository](https://github.com/yt-dlp/yt-dlp).

## 📥 Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/youtube_desktop.git
    cd youtube_desktop
    ```

2.  **Install Flutter dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the application:**
    ```bash
    flutter run -d windows
    ```

##  Authentication (Cookies)

For downloading age-restricted videos or content that requires login:

1.  Install a browser extension like **"Get cookies.txt LOCALLY"**.
2.  Log in to YouTube in your browser.
3.  Export the cookies and save them as `cookies.txt` in the application's root directory.
4.  The application will automatically detect and use the cookies for `yt-dlp` operations.

## Built With

-   [Flutter](https://flutter.dev/) - UI Framework
-   [webview_windows](https://pub.dev/packages/webview_windows) - Native Windows WebView
-   [yt-dlp](https://github.com/yt-dlp/yt-dlp) - Command-line media downloader
-   [path_provider](https://pub.dev/packages/path_provider) - File system access

## Roadmap

-   [ ] Full implementation of Album Maker metadata editor.
-   [ ] Support for batch downloading playlists.
-   [ ] Integrated media player.
-   [ ] Custom download directory selection.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
