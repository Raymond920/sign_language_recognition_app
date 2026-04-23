import 'package:flutter/material.dart';

class StatItemData {
  final String title;
  final String value;
  final Color? valueColor;
  final Color? titleColor;
  
  StatItemData({
    required this.title,
    required this.value,
    this.valueColor,
    this.titleColor,
  });
}

class UserStatsCard extends StatelessWidget {
  const UserStatsCard({
    super.key,
    required this.header,
    required this.stats,
  });

  final String header;
  final List<StatItemData> stats;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? colorScheme.outlineVariant : Colors.grey.shade200,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  header,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? colorScheme.onSurface : Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            stats[0].value,
                            style: TextStyle(
                              color: stats[0].valueColor,
                              fontSize: 24
                            ),
                          ),
                          Text(
                            stats[0].title,
                            style: TextStyle(
                              color: stats[0].titleColor
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            stats[1].value,
                            style: TextStyle(
                              color: stats[1].valueColor,
                              fontSize: 24
                            ),
                          ),
                          Text(
                            stats[1].title,
                            style: TextStyle(
                              color: stats[1].titleColor
                            ),
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            stats[2].value,
                            style: TextStyle(
                              color: stats[2].valueColor,
                              fontSize: 24
                            ),
                          ),
                          Text(
                            stats[2].title,
                            style: TextStyle(
                              color: stats[2].titleColor
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                )
              ],
            )
            // Text(
            //   header,
            //   style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            // ),
            // const SizedBox(height: 16),
            // GridView.count(
            //   crossAxisCount: 3,
            //   shrinkWrap: true,
            //   physics: NeverScrollableScrollPhysics(),
            //   padding: const EdgeInsets.symmetric(horizontal: 20),
            //   crossAxisSpacing: 20,
            //   mainAxisSpacing: 20,
            //   children: stats
            //       .map((stat) => StatItem(
            //         stat.title,
            //         stat.value,
            //         stat.valueColor,
            //         stat.titleColor,
            //       ))
            //       .toList(),
            // )
          ],
        ),
    );
  }
}

class StatItem extends StatelessWidget {
  const StatItem(
    this.statTitle, 
    this.statValue, 
    this.valueColor, 
    this.titleColor, 
    {super.key}
  );

  final String statTitle;
  final String statValue;
  final Color? valueColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            statValue,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: valueColor ?? Color.fromRGBO(6, 182, 212, 1.0),
              fontWeight: FontWeight.w500,
              fontSize: 26,
            ),
          ),
          Text(
            statTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor ?? Color.fromRGBO(0, 0, 0, 0.5),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}