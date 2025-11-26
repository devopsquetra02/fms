/// Model representing a job item.
class JobItem {
  final String id;
  final String title;
  final String address;
  final String detail;

  const JobItem({
    required this.id,
    required this.title,
    required this.address,
    required this.detail,
  });
}
