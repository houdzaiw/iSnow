// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blocked_user.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetBlockedUserCollection on Isar {
  IsarCollection<BlockedUser> get blockedUsers => this.collection();
}

const BlockedUserSchema = CollectionSchema(
  name: r'BlockedUser',
  id: 6978690186555197398,
  properties: {
    r'avatar': PropertySchema(
      id: 0,
      name: r'avatar',
      type: IsarType.string,
    ),
    r'blockedAt': PropertySchema(
      id: 1,
      name: r'blockedAt',
      type: IsarType.dateTime,
    ),
    r'blockedUserId': PropertySchema(
      id: 2,
      name: r'blockedUserId',
      type: IsarType.long,
    ),
    r'nick': PropertySchema(
      id: 3,
      name: r'nick',
      type: IsarType.string,
    )
  },
  estimateSize: _blockedUserEstimateSize,
  serialize: _blockedUserSerialize,
  deserialize: _blockedUserDeserialize,
  deserializeProp: _blockedUserDeserializeProp,
  idName: r'id',
  indexes: {
    r'blockedUserId': IndexSchema(
      id: -3548665784055367328,
      name: r'blockedUserId',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'blockedUserId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _blockedUserGetId,
  getLinks: _blockedUserGetLinks,
  attach: _blockedUserAttach,
  version: '3.1.0+1',
);

int _blockedUserEstimateSize(
  BlockedUser object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.avatar;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.nick;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _blockedUserSerialize(
  BlockedUser object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.avatar);
  writer.writeDateTime(offsets[1], object.blockedAt);
  writer.writeLong(offsets[2], object.blockedUserId);
  writer.writeString(offsets[3], object.nick);
}

BlockedUser _blockedUserDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = BlockedUser();
  object.avatar = reader.readStringOrNull(offsets[0]);
  object.blockedAt = reader.readDateTime(offsets[1]);
  object.blockedUserId = reader.readLong(offsets[2]);
  object.id = id;
  object.nick = reader.readStringOrNull(offsets[3]);
  return object;
}

P _blockedUserDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringOrNull(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _blockedUserGetId(BlockedUser object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _blockedUserGetLinks(BlockedUser object) {
  return [];
}

void _blockedUserAttach(
    IsarCollection<dynamic> col, Id id, BlockedUser object) {
  object.id = id;
}

extension BlockedUserByIndex on IsarCollection<BlockedUser> {
  Future<BlockedUser?> getByBlockedUserId(int blockedUserId) {
    return getByIndex(r'blockedUserId', [blockedUserId]);
  }

  BlockedUser? getByBlockedUserIdSync(int blockedUserId) {
    return getByIndexSync(r'blockedUserId', [blockedUserId]);
  }

  Future<bool> deleteByBlockedUserId(int blockedUserId) {
    return deleteByIndex(r'blockedUserId', [blockedUserId]);
  }

  bool deleteByBlockedUserIdSync(int blockedUserId) {
    return deleteByIndexSync(r'blockedUserId', [blockedUserId]);
  }

  Future<List<BlockedUser?>> getAllByBlockedUserId(
      List<int> blockedUserIdValues) {
    final values = blockedUserIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'blockedUserId', values);
  }

  List<BlockedUser?> getAllByBlockedUserIdSync(List<int> blockedUserIdValues) {
    final values = blockedUserIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'blockedUserId', values);
  }

  Future<int> deleteAllByBlockedUserId(List<int> blockedUserIdValues) {
    final values = blockedUserIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'blockedUserId', values);
  }

  int deleteAllByBlockedUserIdSync(List<int> blockedUserIdValues) {
    final values = blockedUserIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'blockedUserId', values);
  }

  Future<Id> putByBlockedUserId(BlockedUser object) {
    return putByIndex(r'blockedUserId', object);
  }

  Id putByBlockedUserIdSync(BlockedUser object, {bool saveLinks = true}) {
    return putByIndexSync(r'blockedUserId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByBlockedUserId(List<BlockedUser> objects) {
    return putAllByIndex(r'blockedUserId', objects);
  }

  List<Id> putAllByBlockedUserIdSync(List<BlockedUser> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'blockedUserId', objects, saveLinks: saveLinks);
  }
}

extension BlockedUserQueryWhereSort
    on QueryBuilder<BlockedUser, BlockedUser, QWhere> {
  QueryBuilder<BlockedUser, BlockedUser, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterWhere> anyBlockedUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'blockedUserId'),
      );
    });
  }
}

extension BlockedUserQueryWhere
    on QueryBuilder<BlockedUser, BlockedUser, QWhereClause> {
  QueryBuilder<BlockedUser, BlockedUser, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterWhereClause>
      blockedUserIdEqualTo(int blockedUserId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'blockedUserId',
        value: [blockedUserId],
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterWhereClause>
      blockedUserIdNotEqualTo(int blockedUserId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'blockedUserId',
              lower: [],
              upper: [blockedUserId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'blockedUserId',
              lower: [blockedUserId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'blockedUserId',
              lower: [blockedUserId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'blockedUserId',
              lower: [],
              upper: [blockedUserId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterWhereClause>
      blockedUserIdGreaterThan(
    int blockedUserId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'blockedUserId',
        lower: [blockedUserId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterWhereClause>
      blockedUserIdLessThan(
    int blockedUserId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'blockedUserId',
        lower: [],
        upper: [blockedUserId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterWhereClause>
      blockedUserIdBetween(
    int lowerBlockedUserId,
    int upperBlockedUserId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'blockedUserId',
        lower: [lowerBlockedUserId],
        includeLower: includeLower,
        upper: [upperBlockedUserId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension BlockedUserQueryFilter
    on QueryBuilder<BlockedUser, BlockedUser, QFilterCondition> {
  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> avatarIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'avatar',
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition>
      avatarIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'avatar',
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> avatarEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition>
      avatarGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'avatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> avatarLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'avatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> avatarBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'avatar',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition>
      avatarStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'avatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> avatarEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'avatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> avatarContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'avatar',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> avatarMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'avatar',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition>
      avatarIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'avatar',
        value: '',
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition>
      avatarIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'avatar',
        value: '',
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition>
      blockedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition>
      blockedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'blockedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition>
      blockedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'blockedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition>
      blockedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'blockedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition>
      blockedUserIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'blockedUserId',
        value: value,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition>
      blockedUserIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'blockedUserId',
        value: value,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition>
      blockedUserIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'blockedUserId',
        value: value,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition>
      blockedUserIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'blockedUserId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> nickIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'nick',
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition>
      nickIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'nick',
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> nickEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nick',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> nickGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nick',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> nickLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nick',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> nickBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nick',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> nickStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nick',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> nickEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nick',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> nickContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nick',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> nickMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nick',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition> nickIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nick',
        value: '',
      ));
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterFilterCondition>
      nickIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nick',
        value: '',
      ));
    });
  }
}

extension BlockedUserQueryObject
    on QueryBuilder<BlockedUser, BlockedUser, QFilterCondition> {}

extension BlockedUserQueryLinks
    on QueryBuilder<BlockedUser, BlockedUser, QFilterCondition> {}

extension BlockedUserQuerySortBy
    on QueryBuilder<BlockedUser, BlockedUser, QSortBy> {
  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy> sortByAvatar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatar', Sort.asc);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy> sortByAvatarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatar', Sort.desc);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy> sortByBlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockedAt', Sort.asc);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy> sortByBlockedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockedAt', Sort.desc);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy> sortByBlockedUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockedUserId', Sort.asc);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy>
      sortByBlockedUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockedUserId', Sort.desc);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy> sortByNick() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nick', Sort.asc);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy> sortByNickDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nick', Sort.desc);
    });
  }
}

extension BlockedUserQuerySortThenBy
    on QueryBuilder<BlockedUser, BlockedUser, QSortThenBy> {
  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy> thenByAvatar() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatar', Sort.asc);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy> thenByAvatarDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'avatar', Sort.desc);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy> thenByBlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockedAt', Sort.asc);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy> thenByBlockedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockedAt', Sort.desc);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy> thenByBlockedUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockedUserId', Sort.asc);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy>
      thenByBlockedUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'blockedUserId', Sort.desc);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy> thenByNick() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nick', Sort.asc);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QAfterSortBy> thenByNickDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nick', Sort.desc);
    });
  }
}

extension BlockedUserQueryWhereDistinct
    on QueryBuilder<BlockedUser, BlockedUser, QDistinct> {
  QueryBuilder<BlockedUser, BlockedUser, QDistinct> distinctByAvatar(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'avatar', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QDistinct> distinctByBlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockedAt');
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QDistinct> distinctByBlockedUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'blockedUserId');
    });
  }

  QueryBuilder<BlockedUser, BlockedUser, QDistinct> distinctByNick(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nick', caseSensitive: caseSensitive);
    });
  }
}

extension BlockedUserQueryProperty
    on QueryBuilder<BlockedUser, BlockedUser, QQueryProperty> {
  QueryBuilder<BlockedUser, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<BlockedUser, String?, QQueryOperations> avatarProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'avatar');
    });
  }

  QueryBuilder<BlockedUser, DateTime, QQueryOperations> blockedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockedAt');
    });
  }

  QueryBuilder<BlockedUser, int, QQueryOperations> blockedUserIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'blockedUserId');
    });
  }

  QueryBuilder<BlockedUser, String?, QQueryOperations> nickProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nick');
    });
  }
}
