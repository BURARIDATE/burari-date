import assert from "node:assert/strict";
import { test } from "node:test";

import { foursquareApiKey, isUnsuitableForDate, searchSightseeing } from "./sightseeing";

test("喫煙所・麻雀店・パチンコ店・カジノなどは、デートの行き先として出さない", () => {
  for (const place of [
    { name: "Smoking Area - Shinjuku Sta. South", categories: [{ name: "Smoking Area" }] },
    { name: "リーチ麻雀さかえ", categories: [{ name: "Gaming Cafe" }] },
    { name: "マルハン", categories: [{ name: "Pachinko Parlor" }] },
    { name: "Some Place", categories: [{ name: "Arts and Entertainment" }, { name: "Casino" }] },
    { name: "WINS", categories: [{ name: "Off-Track Betting" }] },
    { name: "新宿駅 喫煙所", categories: [] },
  ]) {
    assert.equal(isUnsuitableForDate(place), true, place.name);
  }
});

test("公園・美術館・映画館などは、そのまま出す", () => {
  for (const place of [
    { name: "新宿御苑", categories: [{ name: "Park" }] },
    { name: "Meguro Cinema (目黒シネマ)", categories: [{ name: "Movie Theater" }] },
    { name: "Philatelic Museum (切手の博物館)", categories: [{ name: "Museum" }] },
    { name: "Taito Station", categories: [{ name: "Arcade" }] },
    { name: "名前だけ", categories: undefined },
  ]) {
    assert.equal(isUnsuitableForDate(place), false, place.name);
  }
});

test("検索結果から、デートに向かない場所を除いて返す", async (t) => {
  t.mock.method(foursquareApiKey, "value", () => "test-key");
  t.mock.method(globalThis, "fetch", async () => new Response(JSON.stringify({
    results: [
      { fsq_place_id: "1", name: "新宿御苑", categories: [{ name: "Park" }] },
      { fsq_place_id: "2", name: "Smoking Area", categories: [{ name: "Smoking Area" }] },
      { fsq_place_id: "3", name: "リーチ麻雀", categories: [{ name: "Mahjong Parlor" }] },
    ],
  })));
  const places = await searchSightseeing(35.68, 139.7);
  assert.deepEqual(places.map((p) => p.id), ["1"]);
});
