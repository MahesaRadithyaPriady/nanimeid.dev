import 'package:flutter/material.dart';

// Skeleton untuk carousel/slider
class CarouselSkeleton extends StatelessWidget {
  final double height;
  final double borderRadius;

  const CarouselSkeleton({
    super.key,
    this.height = 200,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// Skeleton untuk anime card
class AnimeCardSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final double imageHeight;

  const AnimeCardSkeleton({
    super.key,
    this.width = 140,
    this.height = 200,
    this.imageHeight = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          Container(
            width: width,
            height: imageHeight,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          // Title skeleton
          Container(
            width: width * 0.85,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          // Rating skeleton
          Container(
            width: width * 0.4,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

// Skeleton untuk horizontal anime list
class AnimeListSkeleton extends StatelessWidget {
  final int itemCount;
  final double cardWidth;
  final double cardHeight;

  const AnimeListSkeleton({
    super.key,
    this.itemCount = 3,
    this.cardWidth = 140,
    this.cardHeight = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return AnimeCardSkeleton(width: cardWidth, height: cardHeight);
        },
      ),
    );
  }
}

// Skeleton untuk section header
class SectionHeaderSkeleton extends StatelessWidget {
  final double titleWidth;
  final double buttonWidth;

  const SectionHeaderSkeleton({
    super.key,
    this.titleWidth = 120,
    this.buttonWidth = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: titleWidth,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Container(
          width: buttonWidth,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

// Skeleton untuk genre chip
class GenreChipSkeleton extends StatelessWidget {
  final double width;
  final double height;

  const GenreChipSkeleton({super.key, this.width = 60, this.height = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

// Skeleton untuk genre list
class GenreListSkeleton extends StatelessWidget {
  final int itemCount;

  const GenreListSkeleton({super.key, this.itemCount = 9});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(itemCount, (index) {
        return GenreChipSkeleton(width: 60 + (index % 3) * 20);
      }),
    );
  }
}

// Skeleton untuk search field
class SearchFieldSkeleton extends StatelessWidget {
  final double height;
  final double borderRadius;

  const SearchFieldSkeleton({
    super.key,
    this.height = 48,
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// Skeleton untuk tabs
class TabsSkeleton extends StatelessWidget {
  final int tabCount;
  final double tabWidth;
  final double tabHeight;

  const TabsSkeleton({
    super.key,
    this.tabCount = 2,
    this.tabWidth = 80,
    this.tabHeight = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(tabCount, (index) {
          return Container(
            margin: EdgeInsets.only(right: index < tabCount - 1 ? 16 : 0),
            width: tabWidth,
            height: tabHeight,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(16),
            ),
          );
        }),
      ),
    );
  }
}
