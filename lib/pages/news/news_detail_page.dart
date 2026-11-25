import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zelvira/components/custom_network_image.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../../models/news_model.dart';

class NewsDetailPage extends StatelessWidget {
  final NewsModel news;
  const NewsDetailPage({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/news');
                    }
                  },
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: CustomNetworkImage(
                news.imageUrl ?? '',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_outlined,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        news.createdAt ?? 'Sep 24, 2026',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (news.author != null) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          news.author!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  HtmlWidget(
                    news.content,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
