import 'package:flutter_test/flutter_test.dart';

import 'package:burari_date/domain/entities/gacha_history_entry.dart';
import 'package:burari_date/domain/entities/gacha_result.dart';
import 'package:burari_date/domain/entities/railway_line.dart';
import 'package:burari_date/domain/entities/station.dart';

void main() {
  group('GachaHistoryEntry', () {
    test('fromGachaResultは駅・路線の全リストではなく必要な項目だけを抜き出す', () {
      const departure = Station(
        id: 's1',
        name: '中野駅',
        lineId: 'l1',
        orderIndex: 0,
      );
      const arrival = Station(
        id: 's2',
        name: '新宿駅',
        lineId: 'l1',
        orderIndex: 3,
      );
      const line = RailwayLine(
        id: 'l1',
        name: '中央線',
        stations: [departure, arrival],
      );
      final result = GachaResult(
        departureStation: departure,
        line: line,
        minStops: 1,
        maxStops: 5,
        direction: GachaDirection.up,
        arrivalStation: arrival,
        stopsCount: 3,
        executedAt: DateTime(2026, 9, 18, 12, 0),
      );

      final entry = GachaHistoryEntry.fromGachaResult(result);

      expect(entry.departureStationName, '中野駅');
      expect(entry.lineName, '中央線');
      expect(entry.arrivalStationName, '新宿駅');
      expect(entry.stopsCount, 3);
      expect(entry.direction, GachaDirection.up);
      expect(entry.executedAt, DateTime(2026, 9, 18, 12, 0));
      // up方面は、路線の最後の駅(終点)の方面。
      expect(entry.directionTerminusName, '新宿駅');
    });

    test('方面の駅名: downは路線の最初の駅、おまかせ(未確定)はnull', () {
      const a = Station(id: 'a', name: '東京駅', lineId: 'l', orderIndex: 0);
      const b = Station(id: 'b', name: '神田駅', lineId: 'l', orderIndex: 1);
      const c = Station(id: 'c', name: '高尾駅', lineId: 'l', orderIndex: 2);
      const line = RailwayLine(id: 'l', name: '中央線', stations: [a, b, c]);
      GachaResult result(GachaDirection direction) => GachaResult(
        departureStation: b,
        line: line,
        minStops: 1,
        maxStops: 1,
        direction: direction,
        arrivalStation: a,
        stopsCount: 1,
        executedAt: DateTime(2026, 11, 10),
      );

      expect(
        GachaHistoryEntry.fromGachaResult(
          result(GachaDirection.down),
        ).directionTerminusName,
        '東京駅',
      );
      expect(
        GachaHistoryEntry.fromGachaResult(
          result(GachaDirection.up),
        ).directionTerminusName,
        '高尾駅',
      );
      expect(
        GachaHistoryEntry.fromGachaResult(
          result(GachaDirection.random),
        ).directionTerminusName,
        isNull,
      );
    });

    test('toJson/fromJsonが値を保ったまま往復する', () {
      final entry = GachaHistoryEntry(
        departureStationName: '中野駅',
        lineName: '中央線',
        arrivalStationName: '新宿駅',
        stopsCount: 3,
        direction: GachaDirection.down,
        executedAt: DateTime(2026, 9, 18, 12, 0),
      );

      final restored = GachaHistoryEntry.fromJson(entry.toJson());

      expect(restored.departureStationName, entry.departureStationName);
      expect(restored.lineName, entry.lineName);
      expect(restored.arrivalStationName, entry.arrivalStationName);
      expect(restored.stopsCount, entry.stopsCount);
      expect(restored.direction, entry.direction);
      expect(restored.executedAt, entry.executedAt);
    });

    test('方面の駅名も往復する。古い履歴(方面の駅名がない)はnullで読める', () {
      final entry = GachaHistoryEntry(
        departureStationName: '中野駅',
        lineName: '中央線',
        arrivalStationName: '新宿駅',
        stopsCount: 3,
        direction: GachaDirection.up,
        executedAt: DateTime(2026, 11, 10),
        directionTerminusName: '高尾駅',
      );
      expect(
        GachaHistoryEntry.fromJson(entry.toJson()).directionTerminusName,
        '高尾駅',
      );

      final old = {
        'departureStationName': '中野駅',
        'lineName': '中央線',
        'arrivalStationName': '新宿駅',
        'stopsCount': 3,
        'direction': 'up',
        'executedAt': '2026-09-18T12:00:00.000',
      };
      expect(GachaHistoryEntry.fromJson(old).directionTerminusName, isNull);
      expect(
        GachaHistoryEntry.fromJson(old).toJson(),
        isNot(contains('directionTerminusName')),
      );
    });
  });
}
