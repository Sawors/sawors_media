import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:sawors_media_client/meta/meta_manager.dart';
import 'package:sawors_media_common/meta.dart';

class HomeDisplay extends StatelessWidget {
  const HomeDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final rng = Random();
    final theme = Theme.of(context);
    final double headSize = clampDouble(
      size.width * 0.6,
      size.height * 0.33,
      size.height * 0.75,
    );
    final bool doMobileView = size.width / size.height < 0.7;
    final posterPadding = clampDouble(size.width / 100, 5, 10);
    final double rowHeight = 480;
    final ClientMetaManager metaManager = GetIt.instance<ClientMetaManager>();
    final movies = metaManager.metas;
    final double posterWidth =
        (rowHeight - (60 + (posterPadding * 2))) * (9 / 16);
    final cover = movies.toList()[rng.nextInt(movies.length)];
    //
    final NEW_MODE = true;
    final TOP_SPACE = true;
    //
    final blurFilter = ImageFilter.blur(sigmaX: 8, sigmaY: 8);

    return Column(
      spacing: 40,
      children: [
        SizedBox(height: 40),
        NEW_MODE
            ? SizedBox(
                height: headSize,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        FutureBuilder(
                          future: metaManager.getResource(
                            cover,
                            MetaResourceIdentifier.backdrop,
                          ),
                          builder: (context, data) {
                            return data.data != null
                                ? Image.memory(
                                    Uint8List.fromList(data.data!),
                                    fit: BoxFit.cover,
                                  )
                                : Container();
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width / 50,
                            vertical: (size.width / 50) + (TOP_SPACE ? 0 : 70),
                          ),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: SizedBox(
                              width: doMobileView
                                  ? size.width * 0.66
                                  : size.width * 0.33,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  spacing: 10,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    ?!doMobileView
                                        ? Align(
                                            alignment: Alignment.topLeft,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(
                                                maxHeight:
                                                    (headSize * 0.25) - 5,
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  15.0,
                                                ),
                                                child: FutureBuilder(
                                                  future: metaManager
                                                      .getResource(
                                                        cover,
                                                        MetaResourceIdentifier
                                                            .logo,
                                                      ),
                                                  builder: (context, data) {
                                                    return data.data != null
                                                        ? Image.memory(
                                                            Uint8List.fromList(
                                                              data.data!,
                                                            ),
                                                            fit: BoxFit.contain,
                                                          )
                                                        : Container();
                                                  },
                                                ),
                                              ),
                                            ),
                                          )
                                        : null,
                                    FutureBuilder(
                                      future: metaManager.getMeta(cover),
                                      builder: (context, asyncSnapshot) {
                                        final meta = asyncSnapshot.data;
                                        if (meta == null) {
                                          return Container();
                                        }
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: BackdropFilter(
                                            filter: blurFilter,
                                            child: ColoredBox(
                                              color: Colors.black.withAlpha(
                                                128,
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  15.0,
                                                ),
                                                child: Column(
                                                  spacing: 10,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,

                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            right: 12,
                                                          ),
                                                      child: Text(
                                                        "${meta.title}  •  ${meta.releaseDate?.year}",
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .displaySmall,
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      spacing: 20,
                                                      children: meta.production
                                                          .where(
                                                            (a) =>
                                                                a.type ==
                                                                PersonMetaType
                                                                    .director,
                                                          )
                                                          .map(
                                                            (v) => Text(
                                                              v.name,
                                                              style:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .textTheme
                                                                      .titleLarge,
                                                            ),
                                                          )
                                                          .toList(
                                                            growable: false,
                                                          ),
                                                    ),
                                                    ConstrainedBox(
                                                      constraints: BoxConstraints(
                                                        maxHeight: doMobileView
                                                            ? headSize -
                                                                  ((((size.width / 50) +
                                                                              (TOP_SPACE ? 0 : 70)) *
                                                                          2) +
                                                                      188)
                                                            : headSize * 0.25,
                                                      ),
                                                      child: SingleChildScrollView(
                                                        child: Center(
                                                          child: Text(
                                                            meta.plot,
                                                            textAlign: TextAlign
                                                                .justify,
                                                            style:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .textTheme
                                                                    .titleMedium,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: AlignmentGeometry.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: SegmentedButton(
                              segments: [
                                ButtonSegment(
                                  value: "previous",
                                  icon: Icon(Icons.chevron_left),
                                ),
                                ButtonSegment(
                                  value: "next",
                                  icon: Icon(Icons.chevron_right),
                                ),
                              ],
                              style: ButtonStyle(
                                side: WidgetStatePropertyAll(BorderSide.none),
                                // backgroundColor: WidgetStatePropertyAll(
                                //   Colors.black.withAlpha(128),
                                // ),
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              multiSelectionEnabled: false,
                              emptySelectionAllowed: true,
                              showSelectedIcon: false,
                              onSelectionChanged: (s) {},
                              selected: {},
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : SizedBox(
                height: headSize,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      File("/home/sawors/Downloads/Movies/$cover/backdrop.jpg"),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                        left: size.width / 50,
                        top: (size.width / 50) + (TOP_SPACE ? 0 : 70),
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          height: (headSize * 0.33) + 10,
                          width: (size.width * 0.33) + 10,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Image.file(
                                fit: BoxFit.contain,
                                alignment: Alignment.topCenter,
                                File(
                                  "/home/sawors/Downloads/Movies/$cover/logo.png",
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: AlignmentGeometry.bottomCenter,
                      child: SizedBox(
                        height: 10,
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.scaffoldBackgroundColor,
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ...List.generate(4, (i) {
          final rOrder = List.of(movies);
          rOrder.shuffle(rng);
          return SizedBox(
            height: rowHeight,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 5, left: 15),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text("Films", style: theme.textTheme.titleLarge),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final movie = rOrder[(index % (rOrder.length)).toInt()];
                      return SizedBox(
                        width: posterWidth + (2 * posterPadding),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(
                            8 + posterPadding,
                          ),
                          onTap: () {},
                          child: Padding(
                            padding: EdgeInsets.all(posterPadding),
                            child: FutureBuilder(
                              future: metaManager.getMeta(movie),
                              builder: (context, asyncSnapshot) {
                                final meta = asyncSnapshot.data;
                                return Column(
                                  spacing: 4,
                                  children: [
                                    Expanded(
                                      child: FutureBuilder(
                                        future: metaManager.getResource(
                                          movie,
                                          MetaResourceIdentifier.poster,
                                        ),
                                        builder: (context, asyncSnapshot) {
                                          return asyncSnapshot.data != null
                                              ? DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: MemoryImage(
                                                        Uint8List.fromList(
                                                          asyncSnapshot.data!,
                                                        ),
                                                      ),
                                                      fit: BoxFit.cover,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Container(),
                                                )
                                              : Container();
                                        },
                                      ),
                                    ),
                                    Container(),
                                    Text(
                                      meta?.title ??
                                          Uri.decodeComponent(
                                            movie
                                                .split("-")
                                                .sublist(
                                                  0,
                                                  movie.split("-").length - 1,
                                                )
                                                .join(" "),
                                          ),
                                      maxLines: 1,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(
                                      width: posterWidth,
                                      child: Text(
                                        meta?.releaseDate?.year.toString() ??
                                            movie.split("-").last,
                                        maxLines: 1,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: theme.dividerColor,
                                            ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    itemExtent: posterWidth + (2 * posterPadding),
                    itemCount: movies.length,
                    cacheExtent: (posterWidth + (2 * posterPadding)) * 12,
                    padding: EdgeInsets.all(posterPadding),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
