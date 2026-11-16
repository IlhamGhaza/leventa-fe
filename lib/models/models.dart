class PropItem {
  final String id;
  final String name;
  final String type;
  final num price;
  final String priceType;
  final String unit;
  final String loc;
  final int beds;
  final int baths;
  final int build;
  final int land;
  final String status;
  final bool featured;
  final String img;
  final String desc;

  const PropItem({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.priceType,
    required this.unit,
    required this.loc,
    required this.beds,
    required this.baths,
    required this.build,
    required this.land,
    required this.status,
    required this.featured,
    required this.img,
    required this.desc,
  });
}

class LeadItem {
  final String id;
  final String customer;
  final String phone;
  final String email;
  final String prop;
  final String status;
  final num budget;
  final String lastContact;
  final String nextFU;
  final String date;

  const LeadItem({
    required this.id,
    required this.customer,
    required this.phone,
    required this.email,
    required this.prop,
    required this.status,
    required this.budget,
    required this.lastContact,
    required this.nextFU,
    required this.date,
  });
}

class ChartData {
  final String m;
  final num v;
  const ChartData(this.m, this.v);
}

class PipelineItem {
  final String label;
  final int count;
  final String color;
  const PipelineItem(this.label, this.count, this.color);
}

class NotifItem {
  final String id;
  final String title;
  final String body;
  final String time;
  final bool read;
  const NotifItem({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.read,
  });
}

class InquiryItem {
  final String id;
  final String prop;
  final String sales;
  final String date;
  final String status;
  final String lastUpdate;
  const InquiryItem({
    required this.id,
    required this.prop,
    required this.sales,
    required this.date,
    required this.status,
    required this.lastUpdate,
  });
}

class TimelineItem {
  final String date;
  final String event;
  final String detail;
  final String type;
  const TimelineItem({
    required this.date,
    required this.event,
    required this.detail,
    required this.type,
  });
}

class ScheduleItem {
  final String id;
  final String customer;
  final String property;
  final String time;
  final String status;
  final String type;
  const ScheduleItem({
    required this.id,
    required this.customer,
    required this.property,
    required this.time,
    required this.status,
    required this.type,
  });
}
