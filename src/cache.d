module cache;

import logger;

import core.time;
import std.container.dlist;
import std.range;
import std.typecons;
import std.experimental.allocator;

class LRUCache(K, V)
{
    this(uint capacity)
    {
        _capacity = capacity;
        removeDeleter();
    }

    Tuple!(V, bool) get(K key)
    {
        auto it = key in _storage;
        return it is null ? tuple(V.init, false) : tuple(update(it), true);
    }

    Tuple!(K, V, MonoTime) recent()
    {
        auto meta = _meta_list.front();
        return tuple(meta.key, _storage[meta.key].value, meta.ts);
    }

    void put(K key, V value)
    {
        _meta_list.insertFront(Meta(key, MonoTime.currTime()));
        _storage[key] = Stored(value, _meta_list[]);
    }

    void set(K key, V value)
    {
        auto it = key in _storage;
        if (it !is null)
        {
            it.value = value;
            update(it);
            return;
        }
        if (_storage.length == _capacity)
        {
            auto meta = _meta_list.back();
            if (_use_deleter)
            {
                _deleter(meta.key, _storage[meta.key].value);
            }
            _storage.remove(meta.key);
            _meta_list.removeBack();
        }

        put(key, value);
    }

    void setDeleter(void delegate(K, V) d)
    {
        _deleter = d;
        _use_deleter = true;
    }

    void removeDeleter()
    {
        _deleter = (K, V){};
        _use_deleter = false;
    }

    @property auto length() const
    {
        return _storage.length;
    }

private:
    private V update(Stored* stored)
    {
        auto lr = stored.r;
        assert(!lr.empty());
        _meta_list.linearRemove(lr.take(1));
        auto meta = lr.front();
        meta.ts = MonoTime.currTime();
        _meta_list.insertFront(meta);
        stored.r = _meta_list[];
        return stored.value;
    }

    uint _capacity;
    struct Meta
    {
        K key;
        MonoTime ts;
    }
    alias MetaList = DList!Meta;
    struct Stored
    {
        V value;
        MetaList.Range r;
    }
    MetaList _meta_list;
    Stored[K] _storage;
    void delegate(K, V) _deleter;
    bool _use_deleter;
}

unittest
{
    auto cache = new LRUCache!(int, int)(3);
    auto res = cache.get(0);
    assert(res[1] == false);
    cache.set(0, 10);
    res = cache.get(0);
    assert(res[0] == 10);
    assert(res[1] == true);
    cache.set(1, 20);
    cache.set(2, 30);
    assert(cache.recent()[1] == 30);
    cache.set(3, 40);
    res = cache.get(0);
    assert(res[1] == false);
    cache.set(4, 50);
    cache.set(5, 60);
    res = cache.get(2);
    assert(res[1] == false);
    res = cache.get(3);
    assert(res[1] == true);
    assert(res[0] == 40);
    cache.set(6, 70);
    res = cache.get(4);
    assert(res[1] == false);
}
