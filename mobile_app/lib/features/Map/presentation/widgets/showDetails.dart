import 'package:flutter/material.dart';
import 'package:mobile_app/models/index.dart';

Widget showDetails(
  BuildContext context, {
  required Report report,
}) {
  final description = report.description?.trim().isNotEmpty == true
      ? report.description!.trim()
      : report.damageType.value;
  final location =
      '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}';

  return Container(
    padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
    decoration: BoxDecoration(
      color: Colors.blueGrey[50],
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _ReportImage(imageUrl: report.imageUrl),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _severityColor(report.severity),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          report.severity.value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(child: Text(location)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Flexible(child: Text(location)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,
              style: IconButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(30, 30),
                maximumSize: const Size(30, 30),
                backgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      const Text(
                        'Reported by',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.status.value,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    ),
  );
}

Color _severityColor(Severity severity) {
  switch (severity) {
    case Severity.low:
      return Colors.green;
    case Severity.medium:
      return Colors.orange;
    case Severity.high:
      return Colors.red;
  }
}

class _ReportImage extends StatelessWidget {
  final String? imageUrl;

  const _ReportImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    if (url == null || url.isEmpty) {
      return _placeholder();
    }

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    return Image.asset(
      url,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.blueGrey[100],
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Colors.blueGrey,
      ),
    );
  }
}
