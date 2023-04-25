<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.



```dart
    ChatTextField(
      themeMode: ThemeMode.dark,
      overlayConstraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.25,
      ),
      mentionBuilder: (context, mentions, selectItem) {
        return ListView.builder(
          padding: const EdgeInsets.all(0),
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemBuilder: (context, index) {
            return ListTile(
              onTap: () {
                selectItem(index);
              },
              leading: const CircleAvatar(
                child: Icon(Icons.ac_unit_outlined),
              ),
              title: Text(mentions.elementAt(index).content),
            );
          },
          itemCount: mentions.length,
        );
      },
      onEditingComplete: () {},
      onChanged: (value) {},
      overlayPosition: OverlayPosition.bottom,
      textEditingController: StyleTextEditingController(
        hashtagData: const [
          "#Hoang1",
          "#Hoang2",
          "#Hoang3",
          "#Hoang4",
          "#Hoang5",
        ],
        mentionData: const [
          "@Nguyen Ngoc Nhu Quynh",
          "@Le Nguyen Phu Hiep",
          "@Nguyen Thanh Hien",
          "@Canh Nguyen",
          "@Nguyen Bui Tran Nguyen",
        ],
      ),
    ),
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
