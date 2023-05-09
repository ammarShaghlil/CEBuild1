PGDMP                 	        {            HangFire    14.5    14.5 W    f           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            g           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            h           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            i           1262    596262    HangFire    DATABASE     n   CREATE DATABASE "HangFire" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'English_United States.1252';
    DROP DATABASE "HangFire";
                postgres    false                        2615    596263    hangfire    SCHEMA        CREATE SCHEMA hangfire;
    DROP SCHEMA hangfire;
                postgres    false            �            1259    596270    counter    TABLE     �   CREATE TABLE hangfire.counter (
    id bigint NOT NULL,
    key text NOT NULL,
    value bigint NOT NULL,
    expireat timestamp without time zone
);
    DROP TABLE hangfire.counter;
       hangfire         heap    postgres    false    4            �            1259    596269    counter_id_seq    SEQUENCE     y   CREATE SEQUENCE hangfire.counter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE hangfire.counter_id_seq;
       hangfire          postgres    false    4    212            j           0    0    counter_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE hangfire.counter_id_seq OWNED BY hangfire.counter.id;
          hangfire          postgres    false    211            �            1259    596278    hash    TABLE     �   CREATE TABLE hangfire.hash (
    id bigint NOT NULL,
    key text NOT NULL,
    field text NOT NULL,
    value text,
    expireat timestamp without time zone,
    updatecount integer DEFAULT 0 NOT NULL
);
    DROP TABLE hangfire.hash;
       hangfire         heap    postgres    false    4            �            1259    596277    hash_id_seq    SEQUENCE     v   CREATE SEQUENCE hangfire.hash_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE hangfire.hash_id_seq;
       hangfire          postgres    false    214    4            k           0    0    hash_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE hangfire.hash_id_seq OWNED BY hangfire.hash.id;
          hangfire          postgres    false    213            �            1259    596289    job    TABLE     '  CREATE TABLE hangfire.job (
    id bigint NOT NULL,
    stateid bigint,
    statename text,
    invocationdata text NOT NULL,
    arguments text NOT NULL,
    createdat timestamp without time zone NOT NULL,
    expireat timestamp without time zone,
    updatecount integer DEFAULT 0 NOT NULL
);
    DROP TABLE hangfire.job;
       hangfire         heap    postgres    false    4            �            1259    596288 
   job_id_seq    SEQUENCE     u   CREATE SEQUENCE hangfire.job_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE hangfire.job_id_seq;
       hangfire          postgres    false    4    216            l           0    0 
   job_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE hangfire.job_id_seq OWNED BY hangfire.job.id;
          hangfire          postgres    false    215            �            1259    596349    jobparameter    TABLE     �   CREATE TABLE hangfire.jobparameter (
    id bigint NOT NULL,
    jobid bigint NOT NULL,
    name text NOT NULL,
    value text,
    updatecount integer DEFAULT 0 NOT NULL
);
 "   DROP TABLE hangfire.jobparameter;
       hangfire         heap    postgres    false    4            �            1259    596348    jobparameter_id_seq    SEQUENCE     ~   CREATE SEQUENCE hangfire.jobparameter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE hangfire.jobparameter_id_seq;
       hangfire          postgres    false    4    227            m           0    0    jobparameter_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE hangfire.jobparameter_id_seq OWNED BY hangfire.jobparameter.id;
          hangfire          postgres    false    226            �            1259    596314    jobqueue    TABLE     �   CREATE TABLE hangfire.jobqueue (
    id bigint NOT NULL,
    jobid bigint NOT NULL,
    queue text NOT NULL,
    fetchedat timestamp without time zone,
    updatecount integer DEFAULT 0 NOT NULL
);
    DROP TABLE hangfire.jobqueue;
       hangfire         heap    postgres    false    4            �            1259    596313    jobqueue_id_seq    SEQUENCE     z   CREATE SEQUENCE hangfire.jobqueue_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE hangfire.jobqueue_id_seq;
       hangfire          postgres    false    4    220            n           0    0    jobqueue_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE hangfire.jobqueue_id_seq OWNED BY hangfire.jobqueue.id;
          hangfire          postgres    false    219            �            1259    596322    list    TABLE     �   CREATE TABLE hangfire.list (
    id bigint NOT NULL,
    key text NOT NULL,
    value text,
    expireat timestamp without time zone,
    updatecount integer DEFAULT 0 NOT NULL
);
    DROP TABLE hangfire.list;
       hangfire         heap    postgres    false    4            �            1259    596321    list_id_seq    SEQUENCE     v   CREATE SEQUENCE hangfire.list_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE hangfire.list_id_seq;
       hangfire          postgres    false    222    4            o           0    0    list_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE hangfire.list_id_seq OWNED BY hangfire.list.id;
          hangfire          postgres    false    221            �            1259    596363    lock    TABLE     �   CREATE TABLE hangfire.lock (
    resource text NOT NULL,
    updatecount integer DEFAULT 0 NOT NULL,
    acquired timestamp without time zone
);
    DROP TABLE hangfire.lock;
       hangfire         heap    postgres    false    4            �            1259    596264    schema    TABLE     ?   CREATE TABLE hangfire.schema (
    version integer NOT NULL
);
    DROP TABLE hangfire.schema;
       hangfire         heap    postgres    false    4            �            1259    596330    server    TABLE     �   CREATE TABLE hangfire.server (
    id text NOT NULL,
    data text,
    lastheartbeat timestamp without time zone NOT NULL,
    updatecount integer DEFAULT 0 NOT NULL
);
    DROP TABLE hangfire.server;
       hangfire         heap    postgres    false    4            �            1259    596338    set    TABLE     �   CREATE TABLE hangfire.set (
    id bigint NOT NULL,
    key text NOT NULL,
    score double precision NOT NULL,
    value text NOT NULL,
    expireat timestamp without time zone,
    updatecount integer DEFAULT 0 NOT NULL
);
    DROP TABLE hangfire.set;
       hangfire         heap    postgres    false    4            �            1259    596337 
   set_id_seq    SEQUENCE     u   CREATE SEQUENCE hangfire.set_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE hangfire.set_id_seq;
       hangfire          postgres    false    4    225            p           0    0 
   set_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE hangfire.set_id_seq OWNED BY hangfire.set.id;
          hangfire          postgres    false    224            �            1259    596299    state    TABLE     �   CREATE TABLE hangfire.state (
    id bigint NOT NULL,
    jobid bigint NOT NULL,
    name text NOT NULL,
    reason text,
    createdat timestamp without time zone NOT NULL,
    data text,
    updatecount integer DEFAULT 0 NOT NULL
);
    DROP TABLE hangfire.state;
       hangfire         heap    postgres    false    4            �            1259    596298    state_id_seq    SEQUENCE     w   CREATE SEQUENCE hangfire.state_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE hangfire.state_id_seq;
       hangfire          postgres    false    218    4            q           0    0    state_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE hangfire.state_id_seq OWNED BY hangfire.state.id;
          hangfire          postgres    false    217            �           2604    596396 
   counter id    DEFAULT     l   ALTER TABLE ONLY hangfire.counter ALTER COLUMN id SET DEFAULT nextval('hangfire.counter_id_seq'::regclass);
 ;   ALTER TABLE hangfire.counter ALTER COLUMN id DROP DEFAULT;
       hangfire          postgres    false    211    212    212            �           2604    596405    hash id    DEFAULT     f   ALTER TABLE ONLY hangfire.hash ALTER COLUMN id SET DEFAULT nextval('hangfire.hash_id_seq'::regclass);
 8   ALTER TABLE hangfire.hash ALTER COLUMN id DROP DEFAULT;
       hangfire          postgres    false    214    213    214            �           2604    596415    job id    DEFAULT     d   ALTER TABLE ONLY hangfire.job ALTER COLUMN id SET DEFAULT nextval('hangfire.job_id_seq'::regclass);
 7   ALTER TABLE hangfire.job ALTER COLUMN id DROP DEFAULT;
       hangfire          postgres    false    215    216    216            �           2604    596465    jobparameter id    DEFAULT     v   ALTER TABLE ONLY hangfire.jobparameter ALTER COLUMN id SET DEFAULT nextval('hangfire.jobparameter_id_seq'::regclass);
 @   ALTER TABLE hangfire.jobparameter ALTER COLUMN id DROP DEFAULT;
       hangfire          postgres    false    226    227    227            �           2604    596488    jobqueue id    DEFAULT     n   ALTER TABLE ONLY hangfire.jobqueue ALTER COLUMN id SET DEFAULT nextval('hangfire.jobqueue_id_seq'::regclass);
 <   ALTER TABLE hangfire.jobqueue ALTER COLUMN id DROP DEFAULT;
       hangfire          postgres    false    219    220    220            �           2604    596508    list id    DEFAULT     f   ALTER TABLE ONLY hangfire.list ALTER COLUMN id SET DEFAULT nextval('hangfire.list_id_seq'::regclass);
 8   ALTER TABLE hangfire.list ALTER COLUMN id DROP DEFAULT;
       hangfire          postgres    false    222    221    222            �           2604    596517    set id    DEFAULT     d   ALTER TABLE ONLY hangfire.set ALTER COLUMN id SET DEFAULT nextval('hangfire.set_id_seq'::regclass);
 7   ALTER TABLE hangfire.set ALTER COLUMN id DROP DEFAULT;
       hangfire          postgres    false    224    225    225            �           2604    596442    state id    DEFAULT     h   ALTER TABLE ONLY hangfire.state ALTER COLUMN id SET DEFAULT nextval('hangfire.state_id_seq'::regclass);
 9   ALTER TABLE hangfire.state ALTER COLUMN id DROP DEFAULT;
       hangfire          postgres    false    218    217    218            S          0    596270    counter 
   TABLE DATA           =   COPY hangfire.counter (id, key, value, expireat) FROM stdin;
    hangfire          postgres    false    212   `_       U          0    596278    hash 
   TABLE DATA           N   COPY hangfire.hash (id, key, field, value, expireat, updatecount) FROM stdin;
    hangfire          postgres    false    214   }_       W          0    596289    job 
   TABLE DATA           t   COPY hangfire.job (id, stateid, statename, invocationdata, arguments, createdat, expireat, updatecount) FROM stdin;
    hangfire          postgres    false    216   �_       b          0    596349    jobparameter 
   TABLE DATA           M   COPY hangfire.jobparameter (id, jobid, name, value, updatecount) FROM stdin;
    hangfire          postgres    false    227   �_       [          0    596314    jobqueue 
   TABLE DATA           N   COPY hangfire.jobqueue (id, jobid, queue, fetchedat, updatecount) FROM stdin;
    hangfire          postgres    false    220   �_       ]          0    596322    list 
   TABLE DATA           G   COPY hangfire.list (id, key, value, expireat, updatecount) FROM stdin;
    hangfire          postgres    false    222   �_       c          0    596363    lock 
   TABLE DATA           A   COPY hangfire.lock (resource, updatecount, acquired) FROM stdin;
    hangfire          postgres    false    228   `       Q          0    596264    schema 
   TABLE DATA           +   COPY hangfire.schema (version) FROM stdin;
    hangfire          postgres    false    210   +`       ^          0    596330    server 
   TABLE DATA           H   COPY hangfire.server (id, data, lastheartbeat, updatecount) FROM stdin;
    hangfire          postgres    false    223   K`       `          0    596338    set 
   TABLE DATA           M   COPY hangfire.set (id, key, score, value, expireat, updatecount) FROM stdin;
    hangfire          postgres    false    225   �`       Y          0    596299    state 
   TABLE DATA           X   COPY hangfire.state (id, jobid, name, reason, createdat, data, updatecount) FROM stdin;
    hangfire          postgres    false    218   a       r           0    0    counter_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('hangfire.counter_id_seq', 1, false);
          hangfire          postgres    false    211            s           0    0    hash_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('hangfire.hash_id_seq', 1, false);
          hangfire          postgres    false    213            t           0    0 
   job_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('hangfire.job_id_seq', 1, false);
          hangfire          postgres    false    215            u           0    0    jobparameter_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('hangfire.jobparameter_id_seq', 1, false);
          hangfire          postgres    false    226            v           0    0    jobqueue_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('hangfire.jobqueue_id_seq', 1, false);
          hangfire          postgres    false    219            w           0    0    list_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('hangfire.list_id_seq', 1, false);
          hangfire          postgres    false    221            x           0    0 
   set_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('hangfire.set_id_seq', 1, false);
          hangfire          postgres    false    224            y           0    0    state_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('hangfire.state_id_seq', 1, false);
          hangfire          postgres    false    217            �           2606    596398    counter counter_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY hangfire.counter
    ADD CONSTRAINT counter_pkey PRIMARY KEY (id);
 @   ALTER TABLE ONLY hangfire.counter DROP CONSTRAINT counter_pkey;
       hangfire            postgres    false    212            �           2606    596533    hash hash_key_field_key 
   CONSTRAINT     Z   ALTER TABLE ONLY hangfire.hash
    ADD CONSTRAINT hash_key_field_key UNIQUE (key, field);
 C   ALTER TABLE ONLY hangfire.hash DROP CONSTRAINT hash_key_field_key;
       hangfire            postgres    false    214    214            �           2606    596407    hash hash_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY hangfire.hash
    ADD CONSTRAINT hash_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY hangfire.hash DROP CONSTRAINT hash_pkey;
       hangfire            postgres    false    214            �           2606    596417    job job_pkey 
   CONSTRAINT     L   ALTER TABLE ONLY hangfire.job
    ADD CONSTRAINT job_pkey PRIMARY KEY (id);
 8   ALTER TABLE ONLY hangfire.job DROP CONSTRAINT job_pkey;
       hangfire            postgres    false    216            �           2606    596467    jobparameter jobparameter_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY hangfire.jobparameter
    ADD CONSTRAINT jobparameter_pkey PRIMARY KEY (id);
 J   ALTER TABLE ONLY hangfire.jobparameter DROP CONSTRAINT jobparameter_pkey;
       hangfire            postgres    false    227            �           2606    596490    jobqueue jobqueue_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY hangfire.jobqueue
    ADD CONSTRAINT jobqueue_pkey PRIMARY KEY (id);
 B   ALTER TABLE ONLY hangfire.jobqueue DROP CONSTRAINT jobqueue_pkey;
       hangfire            postgres    false    220            �           2606    596510    list list_pkey 
   CONSTRAINT     N   ALTER TABLE ONLY hangfire.list
    ADD CONSTRAINT list_pkey PRIMARY KEY (id);
 :   ALTER TABLE ONLY hangfire.list DROP CONSTRAINT list_pkey;
       hangfire            postgres    false    222            �           2606    596389    lock lock_resource_key 
   CONSTRAINT     W   ALTER TABLE ONLY hangfire.lock
    ADD CONSTRAINT lock_resource_key UNIQUE (resource);
 B   ALTER TABLE ONLY hangfire.lock DROP CONSTRAINT lock_resource_key;
       hangfire            postgres    false    228            �           2606    596268    schema schema_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY hangfire.schema
    ADD CONSTRAINT schema_pkey PRIMARY KEY (version);
 >   ALTER TABLE ONLY hangfire.schema DROP CONSTRAINT schema_pkey;
       hangfire            postgres    false    210            �           2606    596536    server server_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY hangfire.server
    ADD CONSTRAINT server_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY hangfire.server DROP CONSTRAINT server_pkey;
       hangfire            postgres    false    223            �           2606    596538    set set_key_value_key 
   CONSTRAINT     X   ALTER TABLE ONLY hangfire.set
    ADD CONSTRAINT set_key_value_key UNIQUE (key, value);
 A   ALTER TABLE ONLY hangfire.set DROP CONSTRAINT set_key_value_key;
       hangfire            postgres    false    225    225            �           2606    596519    set set_pkey 
   CONSTRAINT     L   ALTER TABLE ONLY hangfire.set
    ADD CONSTRAINT set_pkey PRIMARY KEY (id);
 8   ALTER TABLE ONLY hangfire.set DROP CONSTRAINT set_pkey;
       hangfire            postgres    false    225            �           2606    596444    state state_pkey 
   CONSTRAINT     P   ALTER TABLE ONLY hangfire.state
    ADD CONSTRAINT state_pkey PRIMARY KEY (id);
 <   ALTER TABLE ONLY hangfire.state DROP CONSTRAINT state_pkey;
       hangfire            postgres    false    218            �           1259    596380    ix_hangfire_counter_expireat    INDEX     V   CREATE INDEX ix_hangfire_counter_expireat ON hangfire.counter USING btree (expireat);
 2   DROP INDEX hangfire.ix_hangfire_counter_expireat;
       hangfire            postgres    false    212            �           1259    596527    ix_hangfire_counter_key    INDEX     L   CREATE INDEX ix_hangfire_counter_key ON hangfire.counter USING btree (key);
 -   DROP INDEX hangfire.ix_hangfire_counter_key;
       hangfire            postgres    false    212            �           1259    596545    ix_hangfire_hash_expireat    INDEX     P   CREATE INDEX ix_hangfire_hash_expireat ON hangfire.hash USING btree (expireat);
 /   DROP INDEX hangfire.ix_hangfire_hash_expireat;
       hangfire            postgres    false    214            �           1259    596542    ix_hangfire_job_expireat    INDEX     N   CREATE INDEX ix_hangfire_job_expireat ON hangfire.job USING btree (expireat);
 .   DROP INDEX hangfire.ix_hangfire_job_expireat;
       hangfire            postgres    false    216            �           1259    596534    ix_hangfire_job_statename    INDEX     P   CREATE INDEX ix_hangfire_job_statename ON hangfire.job USING btree (statename);
 /   DROP INDEX hangfire.ix_hangfire_job_statename;
       hangfire            postgres    false    216            �           1259    596539 %   ix_hangfire_jobparameter_jobidandname    INDEX     g   CREATE INDEX ix_hangfire_jobparameter_jobidandname ON hangfire.jobparameter USING btree (jobid, name);
 ;   DROP INDEX hangfire.ix_hangfire_jobparameter_jobidandname;
       hangfire            postgres    false    227    227            �           1259    596499 "   ix_hangfire_jobqueue_jobidandqueue    INDEX     a   CREATE INDEX ix_hangfire_jobqueue_jobidandqueue ON hangfire.jobqueue USING btree (jobid, queue);
 8   DROP INDEX hangfire.ix_hangfire_jobqueue_jobidandqueue;
       hangfire            postgres    false    220    220            �           1259    596392 &   ix_hangfire_jobqueue_queueandfetchedat    INDEX     i   CREATE INDEX ix_hangfire_jobqueue_queueandfetchedat ON hangfire.jobqueue USING btree (queue, fetchedat);
 <   DROP INDEX hangfire.ix_hangfire_jobqueue_queueandfetchedat;
       hangfire            postgres    false    220    220            �           1259    596543    ix_hangfire_list_expireat    INDEX     P   CREATE INDEX ix_hangfire_list_expireat ON hangfire.list USING btree (expireat);
 /   DROP INDEX hangfire.ix_hangfire_list_expireat;
       hangfire            postgres    false    222            �           1259    596544    ix_hangfire_set_expireat    INDEX     N   CREATE INDEX ix_hangfire_set_expireat ON hangfire.set USING btree (expireat);
 .   DROP INDEX hangfire.ix_hangfire_set_expireat;
       hangfire            postgres    false    225            �           1259    596553    ix_hangfire_set_key_score    INDEX     Q   CREATE INDEX ix_hangfire_set_key_score ON hangfire.set USING btree (key, score);
 /   DROP INDEX hangfire.ix_hangfire_set_key_score;
       hangfire            postgres    false    225    225            �           1259    596452    ix_hangfire_state_jobid    INDEX     L   CREATE INDEX ix_hangfire_state_jobid ON hangfire.state USING btree (jobid);
 -   DROP INDEX hangfire.ix_hangfire_state_jobid;
       hangfire            postgres    false    218            �           1259    596540    jobqueue_queue_fetchat_jobid    INDEX     f   CREATE INDEX jobqueue_queue_fetchat_jobid ON hangfire.jobqueue USING btree (queue, fetchedat, jobid);
 2   DROP INDEX hangfire.jobqueue_queue_fetchat_jobid;
       hangfire            postgres    false    220    220    220            �           2606    596476 $   jobparameter jobparameter_jobid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY hangfire.jobparameter
    ADD CONSTRAINT jobparameter_jobid_fkey FOREIGN KEY (jobid) REFERENCES hangfire.job(id) ON UPDATE CASCADE ON DELETE CASCADE;
 P   ALTER TABLE ONLY hangfire.jobparameter DROP CONSTRAINT jobparameter_jobid_fkey;
       hangfire          postgres    false    227    3243    216            �           2606    596453    state state_jobid_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY hangfire.state
    ADD CONSTRAINT state_jobid_fkey FOREIGN KEY (jobid) REFERENCES hangfire.job(id) ON UPDATE CASCADE ON DELETE CASCADE;
 B   ALTER TABLE ONLY hangfire.state DROP CONSTRAINT state_jobid_fkey;
       hangfire          postgres    false    218    3243    216            S      x������ � �      U      x������ � �      W      x������ � �      b      x������ � �      [      x������ � �      ]      x������ � �      c      x������ � �      Q      x�34�����       ^   �   x�Eʻ�0 Й~��3%}�K���hb�c(R�b
������9Ë�qi�í��Hg�7�F�������4WNWע$Bc�x�aJ��6S~.��(a�c�3���yX�R�n	i���w@	���\�^jo�צBWkI����+i��^�JIW��+��}.%      `      x������ � �      Y      x������ � �     