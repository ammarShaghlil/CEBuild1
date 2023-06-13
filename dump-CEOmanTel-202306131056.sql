PGDMP         8    
            {         	   CEOmanTel    14.5    14.5 >   A           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            B           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            C           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            D           1262    660561 	   CEOmanTel    DATABASE     o   CREATE DATABASE "CEOmanTel" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'English_United States.1252';
    DROP DATABASE "CEOmanTel";
                postgres    false                        2615    2200    public    SCHEMA        CREATE SCHEMA public;
    DROP SCHEMA public;
                postgres    false            E           0    0    SCHEMA public    COMMENT     6   COMMENT ON SCHEMA public IS 'standard public schema';
                   postgres    false    3            I           1255    660562 '   divideachievedeventsintoperiods(bigint) 	   PROCEDURE     f  CREATE PROCEDURE public.divideachievedeventsintoperiods(IN cycleid bigint)
    LANGUAGE plpgsql
    AS $$
declare
	MaxEventID bigint;
	CycleLastEventID bigint;
	FrequencyID bigint;
begin

	DROP TABLE IF EXISTS EventPeriods;

	CREATE TEMPORARY TABLE  EventPeriods (PeriodStartDate DATE,FromEventID bigint,ToEventID bigint);

	CycleLastEventID := (Select COALESCE(c."LastAchievedCommissionableEventId",0) FROM "Cycle" c  Where c."ID" = cycleid);

	FrequencyID := (Select c."FrequencyId" FROM "Cycle" c Where c."ID" = cycleid);

	MaxEventID := (Select COALESCE(MAX(a."ID"),0) FROM "AchievedEvent" a);


	IF (FrequencyID = 1) THEN 
		INSERT into EventPeriods(PeriodStartDate,FromEventID,ToEventID) Select CAST(NOW() as DATE), CycleLastEventID, MaxEventID;
	END IF;

	IF (FrequencyID = 3) THEN 
			INSERT into EventPeriods(PeriodStartDate,FromEventID,ToEventID)
			
			SELECT  concat(CAST(EXTRACT(YEAR FROM ae."CreatedAt") as char(4)),'-',CAST(to_char(ae."CreatedAt",'MM') as char(2)),'-01'),
					COALESCE(MIN(ae."ID"),0),
					COALESCE(MAX(ae."ID"),0)
			FROM "AchievedEvent" ae
			Where ae."ID" between CycleLastEventID and MaxEventID
			Group By EXTRACT(YEAR FROM ae."CreatedAt"),EXTRACT(MONTH FROM ae."CreatedAt")
			Order By EXTRACT(YEAR FROM ae."CreatedAt"),EXTRACT(MONTH FROM ae."CreatedAt");
	END IF;

	Select * From EventPeriods;
	
end; $$;
 J   DROP PROCEDURE public.divideachievedeventsintoperiods(IN cycleid bigint);
       public          postgres    false    3            R           1255    660563 2   divideachievedeventsintoperiods(bigint, refcursor) 	   PROCEDURE     v  CREATE PROCEDURE public.divideachievedeventsintoperiods(IN cycleid bigint, INOUT result refcursor)
    LANGUAGE plpgsql
    AS $$
declare
	MaxEventID bigint;
	CycleLastEventID bigint;
	FrequencyID bigint;
begin

	DROP TABLE IF EXISTS EventPeriods;

	CREATE TEMPORARY TABLE  EventPeriods (PeriodStartDate DATE,FromEventID bigint,ToEventID bigint);

	CycleLastEventID := (Select COALESCE(c."LastAchievedCommissionableEventId",0) FROM "Cycle" c  Where c."ID" = cycleid);

	FrequencyID := (Select c."FrequencyId" FROM "Cycle" c Where c."ID" = cycleid);

	MaxEventID := (Select COALESCE(MAX(a."ID"),0) FROM "AchievedEvent" a);


	IF (FrequencyID = 1) THEN 
		INSERT into EventPeriods(PeriodStartDate,FromEventID,ToEventID) Select CAST(NOW() as DATE), CycleLastEventID, MaxEventID;
	END IF;

	IF (FrequencyID = 3) THEN 
			INSERT into EventPeriods(PeriodStartDate,FromEventID,ToEventID)
			
			
			SELECT concat(CAST(EXTRACT(YEAR FROM ae."CreatedAt") as char(4)),'-',CAST(to_char(ae."CreatedAt",'MM') as char(2)),'-01') as CreatedAt,COALESCE(MIN(ae."ID"),0),COALESCE(MAX(ae."ID"),0)
			FROM "AchievedEvent" ae
			Where ae."ID" between  CycleLastEventID and MaxEventID
			Group By CreatedAt
			Order By CreatedAt;


	END IF;

	open result for Select PeriodStartDate as PeriodStartDate ,FromEventID as FromEventID ,ToEventID as ToEventID  From EventPeriods;
	
end; $$;
 b   DROP PROCEDURE public.divideachievedeventsintoperiods(IN cycleid bigint, INOUT result refcursor);
       public          postgres    false    3            S           1255    660564 8   getcalculateditemsreadyforpayout(bigint, bigint, bigint) 	   PROCEDURE     "	  CREATE PROCEDURE public.getcalculateditemsreadyforpayout(IN cycletransactionid bigint, IN schemaid bigint, IN instantcommissionrequest bigint)
    LANGUAGE plpgsql
    AS $$

declare
	
begin

		DROP TABLE IF EXISTS EvaluationResultTemp;
	DROP TABLE IF EXISTS SuspiciousRecords;

	CREATE TEMPORARY TABLE  EvaluationResultTemp 
	(
	   ID bigint,
	   MasterDatumID bigint,
	   ElementID bigint,
	   SchemaID bigint ,
	   Amount float,
	   CreationDate DATE,
	   UpdateDate DATE,
	   Dealer varchar(50),
	   StatusID bigint,
	   CycleTransactionID bigint,
	   IsPaymentTransfered bool ,
	   UpdatedBy varchar(50),
	   InstantCommissionRequestID bigint,
	   ReferenceID char(36),
	   PayoutTransactionID bigint
	);
	
	CREATE TEMPORARY TABLE  SuspiciousRecords 
	(
	   ID bigint,
	   MasterDatumID bigint,
	   ElementID bigint,
	   ReferenceID char(36)
	);

	Insert Into EvaluationResultTemp Select  er."ID",
		er."MasterDatumID",
		er."ElementID",
		er."SchemaID",
		er."Amount",
		er."CreationDate",
		er."UpdateDate",
		er."Dealer",
		er."StatusID",
		er."CycleTransactionID",
		er."IsPaymentTransfered",
		er."UpdatedBy",
		er."InstantCommissionRequestID",
		er."ReferenceId",
		er."PayoutTransactionID"
		From "EvaluationResult" er
		Where er."ID" > 0 and er."StatusID" in (4,7) and er."IsPaymentTransfered" = false  
		and (er."CycleTransactionID" is null or er."CycleTransactionID" = CycleTransactionId)
		and (er."SchemaID" is null or er."SchemaID" = SchemaId);
		--and (er."InstantCommissionRequestID" is null or er."InstantCommissionRequestID" = InstantCommissionRequest);

	
		Insert Into SuspiciousRecords Select Distinct ID,MasterDatumID,ElementID,ReferenceID From EvaluationResultTemp;
	
		Insert Into SuspiciousRecords 
		Select ER."ID" ,ER."MasterDatumID",ER."ElementID",ER."ReferenceId"
		From SuspiciousRecords as S
		inner JOIN "EvaluationResult" ER on ER."MasterDatumID" = S.MasterDatumID 
		and ER."ElementID" = S.ElementID and (ER."ReferenceId" = S.ReferenceID or ER."ReferenceId" IS NULL);
	
		Delete from SuspiciousRecords where ID = 0 or ID is null;
	
		Delete from EvaluationResultTemp as E
	    USING  "EvaluationResult" ER 
		where ER."MasterDatumID" = E.MasterDatumID and ER."ElementID" = E.ElementID and ER."IsPaymentTransfered" = true;
							
		--Select * From EvaluationResultTemp where Amount > 0;
	
end; 
$$;
 �   DROP PROCEDURE public.getcalculateditemsreadyforpayout(IN cycletransactionid bigint, IN schemaid bigint, IN instantcommissionrequest bigint);
       public          postgres    false    3            T           1255    660565 /   getcycletransactionschemastatus(bigint, bigint)    FUNCTION     z  CREATE FUNCTION public.getcycletransactionschemastatus(cycletransactionid bigint, schemaid bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    Count bigint;
    Result bigint;
BEGIN

	 Count := (select count(*) from( SELECT distinct er."StatusID" from "EvaluationResult" er 
				where  er."CycleTransactionID" = CycleTransactionID
				and   er."SchemaID" = SchemaID
				group by er."StatusID") as "StatusRows");

	 IF Count = 1 
	 THEN
		 Result := (select distinct er."StatusID" from "EvaluationResult" er 
					where er."CycleTransactionID" = CycleTransactionID
					and er."SchemaID" = SchemaID);
                    
	 ELSEIF Count = 0 
	  THEN
		Result := (select s."ID"  from  "Status" s  where s."Name"  = 'Initial');
	 ELSE 
		Result := (select s."ID"  from  "Status" s  where s."Name"  = 'Mixed');
	 END IF;
    
    RETURN Result;
END;
$$;
 b   DROP FUNCTION public.getcycletransactionschemastatus(cycletransactionid bigint, schemaid bigint);
       public          postgres    false    3            U           1255    660566 !   getcycletransactionstatus(bigint)    FUNCTION     U  CREATE FUNCTION public.getcycletransactionstatus(cycletransactionid bigint) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    CountEvaluationResults bigint;
    Result bigint;
BEGIN
    
	 CountEvaluationResults := (select count(*) from( SELECT distinct er."StatusID" from "EvaluationResult" er 
					where er."CycleTransactionID" = CycleTransactionID
					group by er."StatusID") as StatusRows);
									
	 if CountEvaluationResults = 1 
	 THEN
		Result := (select distinct er."StatusID" from "EvaluationResult" er 
				where er."CycleTransactionID" = CycleTransactionID);	
			
	 ELSEIF CountEvaluationResults = 0 
	 THEN
		Result := (select s."ID"  from  "Status" s  where s."Name"  = 'Initial');
	 ELSE 
		Result := (select s."ID"  from  "Status" s  where s."Name"  = 'Mixed');
	 END IF;

    RETURN result;
END;
$$;
 K   DROP FUNCTION public.getcycletransactionstatus(cycletransactionid bigint);
       public          postgres    false    3            V           1255    660567 �   getmonthlyactivation(character varying, character varying, character varying, character varying, character varying, character varying, character varying, bit) 	   PROCEDURE       CREATE PROCEDURE public.getmonthlyactivation(IN fromdate character varying, IN todate character varying, IN extracondition character varying, IN imsi character varying, IN activatedby character varying, IN fromeventid character varying, IN toeventid character varying, IN withevaluationresults bit)
    LANGUAGE plpgsql
    AS $$
declare
	IDFrom bigint;
	IDTo bigint;
	SQLQuery varchar(4000);
begin

	IDFrom  :=  (select GETNearestID(FromDate));
	IDTo  := (select GETNearestID(ToDate));
	SQLQuery  := '';


	
	
end; $$;
 *  DROP PROCEDURE public.getmonthlyactivation(IN fromdate character varying, IN todate character varying, IN extracondition character varying, IN imsi character varying, IN activatedby character varying, IN fromeventid character varying, IN toeventid character varying, IN withevaluationresults bit);
       public          postgres    false    3            W           1255    660568    getnearestid(date)    FUNCTION     W  CREATE FUNCTION public.getnearestid(targetdate date) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
	min bigint;
	max bigint;
	mid bigint;
	Boundaries bigint = 0;
	tempDate DATE;
	ID bigint;
BEGIN
    
	IF TargetDate is null
	THEN
		TargetDate := CAST(NOW() AS Date);
	END IF;
	
	min := (Select min(a."ID") From "Activation" a );

	max := (Select max(a."ID") From "Activation" a );
	
	IF(min = max)
	THEN
		ID := min;
	ELSE
		
		 LOOP

		 	EXIT WHEN min <= max;
			
			Boundaries := 1;
			mid := (min + max) / 2;  
			tempDate := (Select a."ActivationDate" From "Activation" a  where a."ID" = mid);
			
			LOOP 
				EXIT WHEN ROWCOUNT = 0;
				
				Boundaries := Boundaries*2;
				
				tempDate := (select L."ActivationDate"
								from "Activation" L
								INNER JOIN  (select j."ID"
											 from "Activation" j 
											 where j."ID" between mid - Boundaries and mid + Boundaries
											 order by j."ID"
											 limit 50)  as L2
								ON L."ID" = L2."ID"
								order by L."ID" desc
								limit 1);
				
			END LOOP; 
			
			 IF(TargetDate = TempDate)
			 THEN
			   	mid := mid + 1;
			 ELSEIF (TargetDate < @TempDate) 
			 THEN  
			    max := mid-1; 
			 ELSE
				mid := mid+1;
			 END IF;
			
		 END LOOP; 
		 
		 ID := mid;
		
	END IF;
	
    RETURN ID;
END;
$$;
 4   DROP FUNCTION public.getnearestid(targetdate date);
       public          postgres    false    3            X           1255    660569 >   reclaiminstantcommissionrequestlogs(integer, integer, integer) 	   PROCEDURE     �  CREATE PROCEDURE public.reclaiminstantcommissionrequestlogs(IN instantcommissionrequestid integer, IN commissiondataid integer, IN startlogid integer)
    LANGUAGE plpgsql
    AS $$
declare
	Diff varchar(20);
begin

	Update "InstantCommissionRequestLog"
	Set "InstantCommissionRequestID" = InstantCommissionRequestID, "MasterDatumID" = CommissionDataID
	Where "ID" = StartLogID;

	Update "InstantCommissionRequestLog"
	Set "CommissionDataID" = CommissionDataID
	Where "InstantCommissionRequestID" = InstantCommissionRequestID and "MasterDatumID" = CommissionDataID;

	Select Diff = CAST(i."CreationDate" as char(20))
	From "InstantCommissionRequestLog"
	Where "ID" = StartLogID;

    INSERT INTO "InstantCommissionRequestLog"
		("InstantCommissionRequestID"
		,"MasterDatumID"
		,"CreationDate"
		,"Type"
		,"Text"
		,"Description",
		"CreatedBy")
	VALUES
		(InstantCommissionRequestID
		,CommissionDataID
		,GETDATE()
		,'Performance'
		,'Performance'
		,Diff
		,'SP');

end; $$;
 �   DROP PROCEDURE public.reclaiminstantcommissionrequestlogs(IN instantcommissionrequestid integer, IN commissiondataid integer, IN startlogid integer);
       public          postgres    false    3            Y           1255    660570    testgetcycle(bigint) 	   PROCEDURE     �   CREATE PROCEDURE public.testgetcycle(IN cycleid bigint)
    LANGUAGE plpgsql
    AS $$
declare

begin
	
	
Select "ID"  From "Cycle" c where "ID" = cycleid;
	
end; $$;
 7   DROP PROCEDURE public.testgetcycle(IN cycleid bigint);
       public          postgres    false    3            Z           1255    660571    testgetcycle(bigint, refcursor) 	   PROCEDURE     �   CREATE PROCEDURE public.testgetcycle(IN cycleid bigint, INOUT result refcursor)
    LANGUAGE plpgsql
    AS $$
declare

begin
	
	
open result for Select *  From "Cycle" c where "ID" = cycleid;
	
end; $$;
 O   DROP PROCEDURE public.testgetcycle(IN cycleid bigint, INOUT result refcursor);
       public          postgres    false    3            [           1255    660572    testsa() 	   PROCEDURE     �   CREATE PROCEDURE public.testsa()
    LANGUAGE plpgsql
    AS $$
declare
	SQLQuery text;
begin

	SQLQuery := 'select * from "Cycle" c';

 	RAISE NOTICE '%', SQLQuery;
	
	EXECUTE 'select * from "Cycle" c';
	
end; $$;
     DROP PROCEDURE public.testsa();
       public          postgres    false    3            �            1259    660573    achievedevent_id_seq    SEQUENCE     }   CREATE SEQUENCE public.achievedevent_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.achievedevent_id_seq;
       public          postgres    false    3            �            1259    660574    AchievedEvent    TABLE     �  CREATE TABLE public."AchievedEvent" (
    "ID" bigint DEFAULT nextval('public.achievedevent_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "EventTypeID" bigint NOT NULL,
    "EventDate" timestamp(0) without time zone,
    "ReferenceID" character varying(108)
);
 #   DROP TABLE public."AchievedEvent";
       public         heap    postgres    false    209    3            �            1259    660580    acitvitychannel_id_seq    SEQUENCE        CREATE SEQUENCE public.acitvitychannel_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.acitvitychannel_id_seq;
       public          postgres    false    3            �            1259    660581    AcitvityChannel    TABLE     �   CREATE TABLE public."AcitvityChannel" (
    "ID" bigint DEFAULT nextval('public.acitvitychannel_id_seq'::regclass) NOT NULL,
    "Type" text
);
 %   DROP TABLE public."AcitvityChannel";
       public         heap    postgres    false    211    3            �            1259    660587    activation_id_seq    SEQUENCE     z   CREATE SEQUENCE public.activation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.activation_id_seq;
       public          postgres    false    3            �            1259    660588 
   Activation    TABLE     �  CREATE TABLE public."Activation" (
    "ID" bigint DEFAULT nextval('public.activation_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "IMSI" character varying(15) NOT NULL,
    "MSISDN" character varying(16) NOT NULL,
    "ActivationDate" timestamp(0) without time zone,
    "ActivatedBy" character varying(100) NOT NULL,
    "ActivatedByClassID" integer NOT NULL,
    "SoldTo" character varying(100) NOT NULL,
    "SoldToClassID" integer NOT NULL,
    "IsEligibleForCrossSelling" boolean NOT NULL
);
     DROP TABLE public."Activation";
       public         heap    postgres    false    213    3            �            1259    660594    activationextension_id_seq    SEQUENCE     �   CREATE SEQUENCE public.activationextension_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.activationextension_id_seq;
       public          postgres    false    3            �            1259    660595    ActivationExtension    TABLE     �  CREATE TABLE public."ActivationExtension" (
    "ID" bigint DEFAULT nextval('public.activationextension_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "Email" text NOT NULL,
    "ActivationGeoLocation" text NOT NULL,
    "ActivationTagName" text NOT NULL,
    "SimType" text NOT NULL,
    "ICCID" text NOT NULL
);
 )   DROP TABLE public."ActivationExtension";
       public         heap    postgres    false    215    3            �            1259    660601    cacheupdatedtables_id_seq    SEQUENCE     �   CREATE SEQUENCE public.cacheupdatedtables_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.cacheupdatedtables_id_seq;
       public          postgres    false    3            �            1259    660602    CacheUpdatedTables    TABLE     h  CREATE TABLE public."CacheUpdatedTables" (
    "ID" bigint DEFAULT nextval('public.cacheupdatedtables_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "EntryName" text,
    "LastUpdatedTime" timestamp(0) without time zone
);
 (   DROP TABLE public."CacheUpdatedTables";
       public         heap    postgres    false    217    3            �            1259    660608    crosssellingmapping_id_seq    SEQUENCE     �   CREATE SEQUENCE public.crosssellingmapping_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.crosssellingmapping_id_seq;
       public          postgres    false    3            �            1259    660609    CrossSellingMapping    TABLE     q  CREATE TABLE public."CrossSellingMapping" (
    "ID" bigint DEFAULT nextval('public.crosssellingmapping_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "ActivatorClassId" integer NOT NULL,
    "RetailerToClassId" integer NOT NULL
);
 )   DROP TABLE public."CrossSellingMapping";
       public         heap    postgres    false    219    3            �            1259    660615    cycle_id_seq    SEQUENCE     u   CREATE SEQUENCE public.cycle_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.cycle_id_seq;
       public          postgres    false    3            �            1259    660616    Cycle    TABLE     �  CREATE TABLE public."Cycle" (
    "ID" bigint DEFAULT nextval('public.cycle_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "Name" text NOT NULL,
    "ForeignName" text,
    "FrequencyId" bigint NOT NULL,
    "ExecutionTime" time without time zone,
    "CuttOffTime" time without time zone,
    "DayOfMonth" integer NOT NULL,
    "LastDayOfMonth" boolean NOT NULL,
    "DayOfWeek" integer NOT NULL,
    "Lateness" integer NOT NULL,
    "IsEnabled" boolean NOT NULL,
    "CreationDate" timestamp(0) without time zone,
    "UpdatedDate" timestamp(0) without time zone,
    "LastRunDate" timestamp(0) without time zone,
    "LastAchievedCommissionableEventId" bigint,
    "CycleTypeId" bigint NOT NULL,
    "ChannelMemberSalesType" text,
    "ChannelMemberType" text
);
    DROP TABLE public."Cycle";
       public         heap    postgres    false    221    3            �            1259    660622    cycletransaction_id_seq    SEQUENCE     �   CREATE SEQUENCE public.cycletransaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.cycletransaction_id_seq;
       public          postgres    false    3            �            1259    660623    CycleTransaction    TABLE     H  CREATE TABLE public."CycleTransaction" (
    "ID" bigint DEFAULT nextval('public.cycletransaction_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "CycleID" bigint NOT NULL,
    "StartDate" timestamp(0) without time zone,
    "EndDate" timestamp(0) without time zone,
    "IsCompleted" boolean NOT NULL,
    "RunDateTime" timestamp(0) without time zone,
    "CommissionLock" boolean,
    "PayoutLock" boolean
);
 &   DROP TABLE public."CycleTransaction";
       public         heap    postgres    false    223    3            �            1259    660629    cycletransactionschema_id_seq    SEQUENCE     �   CREATE SEQUENCE public.cycletransactionschema_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.cycletransactionschema_id_seq;
       public          postgres    false    3            �            1259    660630    CycleTransactionSchema    TABLE     �  CREATE TABLE public."CycleTransactionSchema" (
    "ID" bigint DEFAULT nextval('public.cycletransactionschema_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "SchemaID" bigint,
    "NumberOfElements" integer NOT NULL,
    "Total" double precision NOT NULL,
    "CycleTransactionID" bigint
);
 ,   DROP TABLE public."CycleTransactionSchema";
       public         heap    postgres    false    225    3            �            1259    660636    cycletype_id_seq    SEQUENCE     y   CREATE SEQUENCE public.cycletype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.cycletype_id_seq;
       public          postgres    false    3            �            1259    660637 	   CycleType    TABLE     5  CREATE TABLE public."CycleType" (
    "ID" bigint DEFAULT nextval('public.cycletype_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "Name" character varying(15) NOT NULL
);
    DROP TABLE public."CycleType";
       public         heap    postgres    false    227    3            �            1259    660643    datadumpstrial_id_seq    SEQUENCE     ~   CREATE SEQUENCE public.datadumpstrial_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.datadumpstrial_id_seq;
       public          postgres    false    3            �            1259    660644    DataDumpsTrial    TABLE     �  CREATE TABLE public."DataDumpsTrial" (
    "ID" bigint DEFAULT nextval('public.datadumpstrial_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "DataDumpType" text,
    "TargetDate" timestamp(0) without time zone,
    "SyncStartDate" timestamp(0) without time zone,
    "SyncEndDate" timestamp(0) without time zone
);
 $   DROP TABLE public."DataDumpsTrial";
       public         heap    postgres    false    229    3            �            1259    660650 !   dealercommissiondatadetail_id_seq    SEQUENCE     �   CREATE SEQUENCE public.dealercommissiondatadetail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 8   DROP SEQUENCE public.dealercommissiondatadetail_id_seq;
       public          postgres    false    3            �            1259    660651    DealerCommissionDataDetail    TABLE     �  CREATE TABLE public."DealerCommissionDataDetail" (
    "ID" bigint DEFAULT nextval('public.dealercommissiondatadetail_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "CommissionDataId" bigint,
    "DealerCode" text NOT NULL,
    "Imsi" text NOT NULL,
    "Msisdn" text NOT NULL,
    "ActivationDate" timestamp(0) without time zone,
    "Uidentifier" text NOT NULL,
    "ActivationProcessName" text NOT NULL,
    "CommissionMeritedClassId" integer NOT NULL,
    "CommissionMerited" text NOT NULL,
    "DealerSchedulePayment" boolean NOT NULL,
    "DealerSegment" integer NOT NULL,
    "DealerPrepaidTarget" integer NOT NULL
);
 0   DROP TABLE public."DealerCommissionDataDetail";
       public         heap    postgres    false    231    3            �            1259    660657    dealercommissiondatum_id_seq    SEQUENCE     �   CREATE SEQUENCE public.dealercommissiondatum_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.dealercommissiondatum_id_seq;
       public          postgres    false    3            �            1259    660658    DealerCommissionDatum    TABLE     �  CREATE TABLE public."DealerCommissionDatum" (
    "ID" bigint DEFAULT nextval('public.dealercommissiondatum_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "DealerCode" text NOT NULL,
    "TotalRecharges" numeric(65,30) NOT NULL,
    "CustomerBase" integer NOT NULL,
    "AverageRecharges" numeric(65,30) NOT NULL,
    "PrepaidTarget" integer NOT NULL,
    "PostpaidTarget" integer NOT NULL,
    "Segment" integer NOT NULL,
    "CommissionTransactionId" bigint,
    "SchemaId" bigint,
    "MasterDatumID" bigint NOT NULL
);
 +   DROP TABLE public."DealerCommissionDatum";
       public         heap    postgres    false    233    3            �            1259    660664 %   dealercommissionextensiondatum_id_seq    SEQUENCE     �   CREATE SEQUENCE public.dealercommissionextensiondatum_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 <   DROP SEQUENCE public.dealercommissionextensiondatum_id_seq;
       public          postgres    false    3            �            1259    660665    DealerCommissionExtensionDatum    TABLE       CREATE TABLE public."DealerCommissionExtensionDatum" (
    "ID" bigint DEFAULT nextval('public.dealercommissionextensiondatum_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "RevenueTarget" numeric(65,30) NOT NULL,
    "TotalRevenue" numeric(65,30) NOT NULL,
    "ActivationTarget" numeric(65,30) NOT NULL,
    "AverageAchievedTarget" numeric(65,30) NOT NULL,
    "MasterDatumID" bigint NOT NULL
);
 4   DROP TABLE public."DealerCommissionExtensionDatum";
       public         heap    postgres    false    235    3            �            1259    660671 ,   dealercycletransactionactivationdatum_id_seq    SEQUENCE     �   CREATE SEQUENCE public.dealercycletransactionactivationdatum_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 C   DROP SEQUENCE public.dealercycletransactionactivationdatum_id_seq;
       public          postgres    false    3            �            1259    660672 %   DealerCycleTransactionActivationDatum    TABLE     a  CREATE TABLE public."DealerCycleTransactionActivationDatum" (
    "ID" bigint DEFAULT nextval('public.dealercycletransactionactivationdatum_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "CycleTransactionId" bigint NOT NULL,
    "DealerCode" text NOT NULL,
    "CommissionDataId" bigint NOT NULL,
    "ActivationOrder" bigint NOT NULL,
    "DealerSegmantId" integer NOT NULL,
    "DealerPrepaidTarget" integer NOT NULL,
    "DealerIsMonthlyCommission" boolean NOT NULL
);
 ;   DROP TABLE public."DealerCycleTransactionActivationDatum";
       public         heap    postgres    false    237    3            �            1259    660678    dealersuspension_id_seq    SEQUENCE     �   CREATE SEQUENCE public.dealersuspension_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.dealersuspension_id_seq;
       public          postgres    false    3            �            1259    660679    DealerSuspension    TABLE     �  CREATE TABLE public."DealerSuspension" (
    "ID" bigint DEFAULT nextval('public.dealersuspension_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "DealerCode" text NOT NULL,
    "SchemaId" bigint NOT NULL,
    "Reason" text NOT NULL,
    "IsActive" boolean NOT NULL,
    "StartDate" timestamp(0) without time zone,
    "EndDate" timestamp(0) without time zone
);
 &   DROP TABLE public."DealerSuspension";
       public         heap    postgres    false    239    3            �            1259    660685    dumptrials_id_seq    SEQUENCE     z   CREATE SEQUENCE public.dumptrials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.dumptrials_id_seq;
       public          postgres    false    3            �            1259    660686 
   DumpTrials    TABLE     .  CREATE TABLE public."DumpTrials" (
    "ID" bigint DEFAULT nextval('public.dumptrials_id_seq'::regclass) NOT NULL,
    "TargetDate" timestamp(0) without time zone,
    "SyncStartDate" timestamp(0) without time zone,
    "SyncEndDate" timestamp(0) without time zone,
    "DumpTypeID" bigint NOT NULL
);
     DROP TABLE public."DumpTrials";
       public         heap    postgres    false    241    3            �            1259    660690    dwhdumpstrial_id_seq    SEQUENCE     }   CREATE SEQUENCE public.dwhdumpstrial_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.dwhdumpstrial_id_seq;
       public          postgres    false    3            �            1259    660691    DwhdumpsTrial    TABLE     �  CREATE TABLE public."DwhdumpsTrial" (
    "ID" bigint DEFAULT nextval('public.dwhdumpstrial_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "TargetDate" timestamp(0) without time zone,
    "SyncStartDate" timestamp(0) without time zone,
    "SyncEndDate" timestamp(0) without time zone
);
 #   DROP TABLE public."DwhdumpsTrial";
       public         heap    postgres    false    243    3            �            1259    660697    dwhtry_id_seq    SEQUENCE     v   CREATE SEQUENCE public.dwhtry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.dwhtry_id_seq;
       public          postgres    false    3            �            1259    660698    Dwhtry    TABLE     T  CREATE TABLE public."Dwhtry" (
    "ID" bigint DEFAULT nextval('public.dwhtry_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "LastRunDate" timestamp(0) without time zone,
    "FileName" text NOT NULL
);
    DROP TABLE public."Dwhtry";
       public         heap    postgres    false    245    3            �            1259    660704    earningcommissiondatum_id_seq    SEQUENCE     �   CREATE SEQUENCE public.earningcommissiondatum_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE public.earningcommissiondatum_id_seq;
       public          postgres    false    3            �            1259    660705    EarningCommissionDatum    TABLE     �  CREATE TABLE public."EarningCommissionDatum" (
    "ID" bigint DEFAULT nextval('public.earningcommissiondatum_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "DealerCode" text NOT NULL,
    "Amount" numeric(65,30) NOT NULL,
    "SchemaId" bigint NOT NULL,
    "MasterDatumID" bigint NOT NULL
);
 ,   DROP TABLE public."EarningCommissionDatum";
       public         heap    postgres    false    247    3            �            1259    660711    element_id_seq    SEQUENCE     w   CREATE SEQUENCE public.element_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.element_id_seq;
       public          postgres    false    3            �            1259    660712    Element    TABLE     �  CREATE TABLE public."Element" (
    "ID" bigint DEFAULT nextval('public.element_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "Name" text NOT NULL,
    "ForeignName" text,
    "Weight" double precision NOT NULL,
    "IsEssential" boolean NOT NULL,
    "Rules" text NOT NULL,
    "SchemaId" bigint NOT NULL,
    "Ordinal" integer NOT NULL,
    "EnableNotifications" boolean NOT NULL,
    "NotificationEventId" bigint,
    "NotificationMessageId" bigint,
    "IsHidden" boolean,
    "RuleBuilderData" text,
    "AllowMultiEvaluation" boolean NOT NULL,
    "MaxWeight" text,
    "UpdateReason" text
);
    DROP TABLE public."Element";
       public         heap    postgres    false    249    3            �            1259    660718    evaluationresult_id_seq    SEQUENCE     �   CREATE SEQUENCE public.evaluationresult_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.evaluationresult_id_seq;
       public          postgres    false    3            �            1259    660719    EvaluationResult    TABLE     �  CREATE TABLE public."EvaluationResult" (
    "ID" bigint DEFAULT nextval('public.evaluationresult_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "ElementID" bigint,
    "SchemaID" bigint,
    "Amount" double precision NOT NULL,
    "CreationDate" timestamp(0) without time zone,
    "UpdateDate" timestamp(0) without time zone,
    "Dealer" text NOT NULL,
    "StatusID" bigint NOT NULL,
    "CycleTransactionID" bigint NOT NULL,
    "IsPaymentTransfered" boolean NOT NULL,
    "UpdatedBy" text,
    "InstantCommissionRequestID" bigint,
    "ReferenceId" character varying(108),
    "PayoutTransactionID" bigint,
    "OldAmount" double precision,
    "IsLocked" boolean,
    "LockExpiration" timestamp(0) without time zone,
    "ChannelMemberSalesType" text,
    "ChannelMemberType" text
);
 &   DROP TABLE public."EvaluationResult";
       public         heap    postgres    false    251    3            �            1259    660725    eventtype_id_seq    SEQUENCE     y   CREATE SEQUENCE public.eventtype_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.eventtype_id_seq;
       public          postgres    false    3            �            1259    660726 	   EventType    TABLE     �  CREATE TABLE public."EventType" (
    "ID" bigint DEFAULT nextval('public.eventtype_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "Name" character varying(25) NOT NULL,
    "IsDynamicEvent" boolean NOT NULL,
    "IsActive" boolean NOT NULL,
    "Code" text NOT NULL
);
    DROP TABLE public."EventType";
       public         heap    postgres    false    253    3            �            1259    660732    frequency_id_seq    SEQUENCE     y   CREATE SEQUENCE public.frequency_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.frequency_id_seq;
       public          postgres    false    3                        1259    660733 	   Frequency    TABLE     5  CREATE TABLE public."Frequency" (
    "ID" bigint DEFAULT nextval('public.frequency_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "Name" character varying(15) NOT NULL
);
    DROP TABLE public."Frequency";
       public         heap    postgres    false    255    3            7           1259    666482    hbborderhistories_id_seq    SEQUENCE     �   CREATE SEQUENCE public.hbborderhistories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.hbborderhistories_id_seq;
       public          postgres    false    3            8           1259    666483    HbborderHistories    TABLE     �  CREATE TABLE public."HbborderHistories" (
    "ID" bigint DEFAULT nextval('public.hbborderhistories_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "OrderID" character varying(150) NOT NULL,
    "FDN" character varying(150) NOT NULL,
    "AccountID" character varying(150) NOT NULL,
    "UserID" character varying(150) NOT NULL,
    "PlanName" character varying(150) NOT NULL,
    "PlanCode" character varying(150) NOT NULL,
    "PlanPrice" double precision NOT NULL,
    "Datetime" timestamp(0) without time zone,
    "BillAccountNo" character varying
);
 '   DROP TABLE public."HbborderHistories";
       public         heap    postgres    false    311    3            :           1259    666671    hbborderpaymenthistories_id_seq    SEQUENCE     �   CREATE SEQUENCE public.hbborderpaymenthistories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE public.hbborderpaymenthistories_id_seq;
       public          postgres    false    3            <           1259    666689    HbborderPaymentHistories    TABLE     H  CREATE TABLE public."HbborderPaymentHistories" (
    "ID" bigint DEFAULT nextval('public.hbborderpaymenthistories_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "TransactionId" text NOT NULL,
    "TransactionBillingId" text NOT NULL,
    "BillAccountNo" text NOT NULL,
    "SysCreationTime" text NOT NULL,
    "TransactionAmount" double precision NOT NULL,
    "SysCreationDate" timestamp without time zone
);
 .   DROP TABLE public."HbborderPaymentHistories";
       public         heap    postgres    false    314    3            ;           1259    666680 %   hbborderpaymenthistoriesschema_id_seq    SEQUENCE     �   CREATE SEQUENCE public.hbborderpaymenthistoriesschema_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 <   DROP SEQUENCE public.hbborderpaymenthistoriesschema_id_seq;
       public          postgres    false    3            =           1259    666713    HbborderPaymentHistoriesSchema    TABLE     �  CREATE TABLE public."HbborderPaymentHistoriesSchema" (
    "ID" bigint DEFAULT nextval('public.hbborderpaymenthistoriesschema_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "OrderID" text,
    "FDN" text,
    "PlanName" text,
    "PlanCode" text,
    "BillAccountNo" text,
    "ActivationDate" timestamp without time zone,
    "BillDate" timestamp without time zone,
    "TransactionAmount" double precision,
    "BillPaymentTransactionIds" text,
    "IsCommissionCalculated" boolean,
    "PlanPrice" double precision,
    "TotalPaidBillAmount" double precision
);
 4   DROP TABLE public."HbborderPaymentHistoriesSchema";
       public         heap    postgres    false    315    3                       1259    660739    instantcommissionrequest_id_seq    SEQUENCE     �   CREATE SEQUENCE public.instantcommissionrequest_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE public.instantcommissionrequest_id_seq;
       public          postgres    false    3                       1259    660740    InstantCommissionRequest    TABLE     �  CREATE TABLE public."InstantCommissionRequest" (
    "ID" bigint DEFAULT nextval('public.instantcommissionrequest_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MSISDN" text NOT NULL,
    "IMSI" text NOT NULL,
    "InstantCommissionType" text NOT NULL,
    "RequestDetails" text NOT NULL,
    "EventRegistered" boolean NOT NULL,
    "Evaluated" boolean NOT NULL,
    "IsPaymentTransferred" boolean NOT NULL,
    "CreationDate" timestamp(0) without time zone,
    "LogId" bigint,
    "CommissionDataId" bigint
);
 .   DROP TABLE public."InstantCommissionRequest";
       public         heap    postgres    false    257    3                       1259    660746 "   instantcommissionrequestlog_id_seq    SEQUENCE     �   CREATE SEQUENCE public.instantcommissionrequestlog_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE public.instantcommissionrequestlog_id_seq;
       public          postgres    false    3                       1259    660747    InstantCommissionRequestLog    TABLE       CREATE TABLE public."InstantCommissionRequestLog" (
    "ID" bigint DEFAULT nextval('public.instantcommissionrequestlog_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "InstantCommissionRequestID" bigint NOT NULL,
    "MasterDatumID" bigint NOT NULL,
    "CreationDate" timestamp(0) without time zone,
    "Type" text NOT NULL,
    "Text" text NOT NULL,
    "Description" text
);
 1   DROP TABLE public."InstantCommissionRequestLog";
       public         heap    postgres    false    259    3                       1259    660753    language_id_seq    SEQUENCE     x   CREATE SEQUENCE public.language_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.language_id_seq;
       public          postgres    false    3                       1259    660754    Language    TABLE     3  CREATE TABLE public."Language" (
    "ID" bigint DEFAULT nextval('public.language_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "Name" character varying(15) NOT NULL
);
    DROP TABLE public."Language";
       public         heap    postgres    false    261    3                       1259    660760 
   log_id_seq    SEQUENCE     s   CREATE SEQUENCE public.log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 !   DROP SEQUENCE public.log_id_seq;
       public          postgres    false    3                       1259    660761    Log    TABLE     �  CREATE TABLE public."Log" (
    "ID" bigint DEFAULT nextval('public.log_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "Source" text NOT NULL,
    "Type" text NOT NULL,
    "Text" text NOT NULL,
    "Description" text,
    "DateTime" timestamp(0) without time zone
);
    DROP TABLE public."Log";
       public         heap    postgres    false    263    3            	           1259    660767    masterdatum_id_seq    SEQUENCE     {   CREATE SEQUENCE public.masterdatum_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.masterdatum_id_seq;
       public          postgres    false    3            
           1259    660768    MasterDatum    TABLE     9  CREATE TABLE public."MasterDatum" (
    "ID" bigint DEFAULT nextval('public.masterdatum_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "Name" character varying(80) NOT NULL
);
 !   DROP TABLE public."MasterDatum";
       public         heap    postgres    false    265    3                       1259    660774    notificationmessage_id_seq    SEQUENCE     �   CREATE SEQUENCE public.notificationmessage_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.notificationmessage_id_seq;
       public          postgres    false    3                       1259    660775    NotificationMessage    TABLE       CREATE TABLE public."NotificationMessage" (
    "ID" bigint DEFAULT nextval('public.notificationmessage_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text
);
 )   DROP TABLE public."NotificationMessage";
       public         heap    postgres    false    267    3                       1259    660781    notificationmessagetext_id_seq    SEQUENCE     �   CREATE SEQUENCE public.notificationmessagetext_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.notificationmessagetext_id_seq;
       public          postgres    false    3                       1259    660782    NotificationMessageText    TABLE     �  CREATE TABLE public."NotificationMessageText" (
    "ID" bigint DEFAULT nextval('public.notificationmessagetext_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "NotificationMessageId" bigint NOT NULL,
    "LanguageId" bigint NOT NULL,
    "Text" text NOT NULL
);
 -   DROP TABLE public."NotificationMessageText";
       public         heap    postgres    false    269    3                       1259    660788    orderhistories_id_seq    SEQUENCE     ~   CREATE SEQUENCE public.orderhistories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.orderhistories_id_seq;
       public          postgres    false    3                       1259    660789    OrderHistories    TABLE     e  CREATE TABLE public."OrderHistories" (
    "ID" bigint DEFAULT nextval('public.orderhistories_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "OrderId" character varying(150) NOT NULL,
    "ContractId" integer NOT NULL,
    "SoldToParty" integer NOT NULL,
    "Plan" character varying(100) NOT NULL,
    "OrderBy" character varying(100) NOT NULL,
    "OrderDate" timestamp(0) without time zone,
    "PlanPrice" double precision NOT NULL
);
 $   DROP TABLE public."OrderHistories";
       public         heap    postgres    false    271    3                       1259    660795    paymenthistories_id_seq    SEQUENCE     �   CREATE SEQUENCE public.paymenthistories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.paymenthistories_id_seq;
       public          postgres    false    3                       1259    660796    PaymentHistories    TABLE     N  CREATE TABLE public."PaymentHistories" (
    "ID" bigint DEFAULT nextval('public.paymenthistories_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "PaymentId" character varying(150) NOT NULL,
    "Total" double precision NOT NULL,
    "Vat" double precision NOT NULL,
    "PaymentDate" timestamp(0) without time zone,
    "ActivationId" character varying(100) NOT NULL,
    "UserId" character varying(100) NOT NULL
);
 &   DROP TABLE public."PaymentHistories";
       public         heap    postgres    false    273    3                       1259    660802    paymentstatus_id_seq    SEQUENCE     }   CREATE SEQUENCE public.paymentstatus_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.paymentstatus_id_seq;
       public          postgres    false    3                       1259    660803    PaymentStatus    TABLE     =  CREATE TABLE public."PaymentStatus" (
    "ID" bigint DEFAULT nextval('public.paymentstatus_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "Name" character varying(50) NOT NULL
);
 #   DROP TABLE public."PaymentStatus";
       public         heap    postgres    false    275    3                       1259    660809    payouttransaction_id_seq    SEQUENCE     �   CREATE SEQUENCE public.payouttransaction_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.payouttransaction_id_seq;
       public          postgres    false    3                       1259    660810    PayoutTransaction    TABLE     �  CREATE TABLE public."PayoutTransaction" (
    "ID" bigint DEFAULT nextval('public.payouttransaction_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "DealerCode" text NOT NULL,
    "SalesPersonCode" text NOT NULL,
    "GrossAmount" double precision NOT NULL,
    "Amount" double precision NOT NULL,
    "PaymentStatusId" smallint NOT NULL,
    "CycleTransactionID" bigint NOT NULL,
    "Payload" text,
    "CreatedDate" timestamp(0) without time zone,
    "LastUpdateDate" timestamp(0) without time zone,
    "SchemaID" bigint,
    "InstantCommissionRequestID" bigint
);
 '   DROP TABLE public."PayoutTransaction";
       public         heap    postgres    false    277    3            3           1259    666454    postpaidhistories_id_seq    SEQUENCE     �   CREATE SEQUENCE public.postpaidhistories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.postpaidhistories_id_seq;
       public          postgres    false    3            4           1259    666455    PostpaidHistories    TABLE     �  CREATE TABLE public."PostpaidHistories" (
    "ID" bigint DEFAULT nextval('public.postpaidhistories_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "OrderID" character varying(150) NOT NULL,
    "Msisdn" character varying(150) NOT NULL,
    "AccountID" character varying(150) NOT NULL,
    "UserID" character varying(150) NOT NULL,
    "PlanName" character varying(150) NOT NULL,
    "PlanCode" character varying(150) NOT NULL,
    "PlanPrice" double precision NOT NULL,
    "Datetime" timestamp(0) without time zone
);
 '   DROP TABLE public."PostpaidHistories";
       public         heap    postgres    false    307    3            >           1259    666806    postpaidpaymenthistories_id_seq    SEQUENCE     �   CREATE SEQUENCE public.postpaidpaymenthistories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE public.postpaidpaymenthistories_id_seq;
       public          postgres    false    3            ?           1259    666807    PostpaidPaymentHistories    TABLE     H  CREATE TABLE public."PostpaidPaymentHistories" (
    "ID" bigint DEFAULT nextval('public.postpaidpaymenthistories_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "TransactionId" text NOT NULL,
    "TransactionBillingId" text NOT NULL,
    "BillAccountNo" text NOT NULL,
    "SysCreationTime" text NOT NULL,
    "TransactionAmount" double precision NOT NULL,
    "SysCreationDate" timestamp without time zone
);
 .   DROP TABLE public."PostpaidPaymentHistories";
       public         heap    postgres    false    318    3            @           1259    666821 %   postpaidpaymenthistoriesschema_id_seq    SEQUENCE     �   CREATE SEQUENCE public.postpaidpaymenthistoriesschema_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 <   DROP SEQUENCE public.postpaidpaymenthistoriesschema_id_seq;
       public          postgres    false    3            A           1259    666822    PostpaidPaymentHistoriesSchema    TABLE     �  CREATE TABLE public."PostpaidPaymentHistoriesSchema" (
    "ID" bigint DEFAULT nextval('public.postpaidpaymenthistoriesschema_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "OrderID" text,
    "FDN" text,
    "PlanName" text,
    "PlanCode" text,
    "BillAccountNo" text,
    "ActivationDate" timestamp without time zone,
    "BillDate" timestamp without time zone,
    "TransactionAmount" double precision,
    "BillPaymentTransactionIds" text,
    "IsCommissionCalculated" boolean,
    "PlanPrice" double precision,
    "TotalPaidBillAmount" double precision
);
 4   DROP TABLE public."PostpaidPaymentHistoriesSchema";
       public         heap    postgres    false    320    3            5           1259    666468    prepaidhistories_id_seq    SEQUENCE     �   CREATE SEQUENCE public.prepaidhistories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.prepaidhistories_id_seq;
       public          postgres    false    3            6           1259    666469    PrepaidHistories    TABLE     �  CREATE TABLE public."PrepaidHistories" (
    "ID" bigint DEFAULT nextval('public.prepaidhistories_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "OrderID" character varying(150) NOT NULL,
    "Msisdn" character varying(150) NOT NULL,
    "AccountID" character varying(150) NOT NULL,
    "UserID" character varying(150) NOT NULL,
    "PlanName" character varying(150) NOT NULL,
    "PlanCode" character varying(150) NOT NULL,
    "PlanPrice" double precision NOT NULL,
    "Datetime" timestamp(0) without time zone,
    "SubscrNo" character varying
);
 &   DROP TABLE public."PrepaidHistories";
       public         heap    postgres    false    309    3            D           1259    666849    prepaidpaymenthistories_id_seq    SEQUENCE     �   CREATE SEQUENCE public.prepaidpaymenthistories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.prepaidpaymenthistories_id_seq;
       public          postgres    false    3            E           1259    666850    PrepaidPaymentHistories    TABLE        CREATE TABLE public."PrepaidPaymentHistories" (
    "ID" bigint DEFAULT nextval('public.prepaidpaymenthistories_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "TransactionId" text NOT NULL,
    "SubscrNo" text NOT NULL,
    "EventHour" text NOT NULL,
    "Amount" double precision NOT NULL,
    "EventDate" timestamp without time zone
);
 -   DROP TABLE public."PrepaidPaymentHistories";
       public         heap    postgres    false    324    3            B           1259    666835 $   prepaidpaymenthistoriesschema_id_seq    SEQUENCE     �   CREATE SEQUENCE public.prepaidpaymenthistoriesschema_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ;   DROP SEQUENCE public.prepaidpaymenthistoriesschema_id_seq;
       public          postgres    false    3            C           1259    666836    PrepaidPaymentHistoriesSchema    TABLE     �  CREATE TABLE public."PrepaidPaymentHistoriesSchema" (
    "ID" bigint DEFAULT nextval('public.prepaidpaymenthistoriesschema_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "OrderID" text,
    "Msisdn" text,
    "PlanName" text,
    "PlanCode" text,
    "PlanPrice" double precision,
    "SubscrNo" text,
    "ActivationDate" timestamp without time zone,
    "BillDate" timestamp without time zone,
    "TransactionAmount" double precision,
    "BillPaymentTransactionIds" text,
    "IsCommissionCalculated" boolean,
    "TotalPaidBillAmount" double precision
);
 3   DROP TABLE public."PrepaidPaymentHistoriesSchema";
       public         heap    postgres    false    322    3                       1259    660816    product_id_seq    SEQUENCE     w   CREATE SEQUENCE public.product_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.product_id_seq;
       public          postgres    false    3                       1259    660817    Product    TABLE     �  CREATE TABLE public."Product" (
    "ID" bigint DEFAULT nextval('public.product_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "Name" text NOT NULL,
    "EventTypeID" bigint NOT NULL,
    "RefId" integer NOT NULL,
    "SubscriptionManagmentId" integer
);
    DROP TABLE public."Product";
       public         heap    postgres    false    279    3                       1259    660823    productselling_id_seq    SEQUENCE     ~   CREATE SEQUENCE public.productselling_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.productselling_id_seq;
       public          postgres    false    3                       1259    660824    ProductSelling    TABLE     �  CREATE TABLE public."ProductSelling" (
    "ID" bigint DEFAULT nextval('public.productselling_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "TransactionId" bigint NOT NULL,
    "ReferenceId" character varying(108) NOT NULL,
    "ActivationID" bigint NOT NULL,
    "ProductID" bigint NOT NULL,
    "Msisdn" text NOT NULL,
    "AccountNo" text NOT NULL,
    "TransactionDate" timestamp(0) without time zone,
    "CreationDate" timestamp(0) without time zone,
    "DealerCode" text NOT NULL,
    "DealerClassId" integer NOT NULL
);
 $   DROP TABLE public."ProductSelling";
       public         heap    postgres    false    281    3                       1259    660830    productsellingexception_id_seq    SEQUENCE     �   CREATE SEQUENCE public.productsellingexception_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.productsellingexception_id_seq;
       public          postgres    false    3                       1259    660831    ProductSellingException    TABLE     �  CREATE TABLE public."ProductSellingException" (
    "ID" bigint DEFAULT nextval('public.productsellingexception_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "LogId" integer NOT NULL,
    "TransactionId" bigint,
    "ReferenceId" character varying(108),
    "ActivationCommissionDataId" bigint,
    "ProductId" bigint,
    "Msisdn" text,
    "AccountNo" text,
    "TransactionDate" timestamp(0) without time zone,
    "CreationDate" timestamp(0) without time zone,
    "DealerCode" text NOT NULL,
    "DealerClassId" integer NOT NULL
);
 -   DROP TABLE public."ProductSellingException";
       public         heap    postgres    false    283    3                       1259    660837    schema_id_seq    SEQUENCE     v   CREATE SEQUENCE public.schema_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.schema_id_seq;
       public          postgres    false    3                       1259    660838    Schema    TABLE     �  CREATE TABLE public."Schema" (
    "ID" bigint DEFAULT nextval('public.schema_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "Name" text NOT NULL,
    "ForeignName" text,
    "Active" boolean NOT NULL,
    "Query" text,
    "CycleID" bigint NOT NULL,
    "CommissionMerited" text,
    "BrandId" integer NOT NULL,
    "NotificationMessageID" bigint,
    "CommissionMeritedClassId" text NOT NULL,
    "CalculationSpecificationID" bigint NOT NULL,
    "ApplicableFrom" timestamp(0) without time zone,
    "ApplicableTo" timestamp(0) without time zone,
    "CreationDate" timestamp(0) without time zone,
    "ChangeLog" text,
    "LastUpdateDate" timestamp(0) without time zone,
    "LastUpdatedBy" text,
    "PaymentMethod" integer,
    "UpdateReason" text,
    "NotificationID" text
);
    DROP TABLE public."Schema";
       public         heap    postgres    false    285    3                       1259    660844 %   schemacalculationspecification_id_seq    SEQUENCE     �   CREATE SEQUENCE public.schemacalculationspecification_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 <   DROP SEQUENCE public.schemacalculationspecification_id_seq;
       public          postgres    false    3                        1259    660845    SchemaCalculationSpecification    TABLE     �  CREATE TABLE public."SchemaCalculationSpecification" (
    "ID" bigint DEFAULT nextval('public.schemacalculationspecification_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "Name" text NOT NULL,
    "BaseQuery" text,
    "SchemaHandlerType" text NOT NULL,
    "AssemblyPath" text NOT NULL,
    "ClassName" text NOT NULL,
    "BasePath" text,
    "SecondaryQuery" text
);
 4   DROP TABLE public."SchemaCalculationSpecification";
       public         heap    postgres    false    287    3            !           1259    660851    schemadealer_id_seq    SEQUENCE     |   CREATE SEQUENCE public.schemadealer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.schemadealer_id_seq;
       public          postgres    false    3            "           1259    660852    SchemaDealer    TABLE     P  CREATE TABLE public."SchemaDealer" (
    "ID" bigint DEFAULT nextval('public.schemadealer_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "SchemaID" bigint NOT NULL,
    "DealerCode" text NOT NULL
);
 "   DROP TABLE public."SchemaDealer";
       public         heap    postgres    false    289    3            #           1259    660858    specialnumberdatum_id_seq    SEQUENCE     �   CREATE SEQUENCE public.specialnumberdatum_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.specialnumberdatum_id_seq;
       public          postgres    false    3            $           1259    660859    SpecialNumberDatum    TABLE     �  CREATE TABLE public."SpecialNumberDatum" (
    "ID" bigint DEFAULT nextval('public.specialnumberdatum_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "Cost" numeric(65,30) NOT NULL,
    "MasterDatumID" bigint NOT NULL,
    "Channel" integer NOT NULL
);
 (   DROP TABLE public."SpecialNumberDatum";
       public         heap    postgres    false    291    3            %           1259    660865    status_id_seq    SEQUENCE     v   CREATE SEQUENCE public.status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.status_id_seq;
       public          postgres    false    3            &           1259    660866    Status    TABLE     /  CREATE TABLE public."Status" (
    "ID" bigint DEFAULT nextval('public.status_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "Name" character varying(50) NOT NULL
);
    DROP TABLE public."Status";
       public         heap    postgres    false    293    3            '           1259    660872    subscriptionplan_id_seq    SEQUENCE     �   CREATE SEQUENCE public.subscriptionplan_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.subscriptionplan_id_seq;
       public          postgres    false    3            (           1259    660873    SubscriptionPlan    TABLE     �  CREATE TABLE public."SubscriptionPlan" (
    "ID" bigint DEFAULT nextval('public.subscriptionplan_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "TypeID" text NOT NULL,
    "MasterDatumID" bigint NOT NULL,
    "Cost" numeric(65,30) NOT NULL,
    "Channel" integer NOT NULL
);
 &   DROP TABLE public."SubscriptionPlan";
       public         heap    postgres    false    295    3            )           1259    660879    subscriptionrefill_id_seq    SEQUENCE     �   CREATE SEQUENCE public.subscriptionrefill_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.subscriptionrefill_id_seq;
       public          postgres    false    3            *           1259    660880    SubscriptionreFill    TABLE     F  CREATE TABLE public."SubscriptionreFill" (
    "ID" bigint DEFAULT nextval('public.subscriptionrefill_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "MSISDN" character varying(16) NOT NULL,
    "TimeStamp" timestamp(0) without time zone,
    "AccountNo" character varying(30) NOT NULL,
    "Amount" numeric(65,30) NOT NULL,
    "ReferenceNo" character varying(30) NOT NULL,
    "Ordinal" integer NOT NULL
);
 (   DROP TABLE public."SubscriptionreFill";
       public         heap    postgres    false    297    3            +           1259    660886    systemconfiguration_id_seq    SEQUENCE     �   CREATE SEQUENCE public.systemconfiguration_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.systemconfiguration_id_seq;
       public          postgres    false    3            ,           1259    660887    SystemConfiguration    TABLE     R  CREATE TABLE public."SystemConfiguration" (
    "ID" bigint DEFAULT nextval('public.systemconfiguration_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "Key" text NOT NULL,
    "Value" text NOT NULL
);
 )   DROP TABLE public."SystemConfiguration";
       public         heap    postgres    false    299    3            -           1259    660893    upgradehistories_id_seq    SEQUENCE     �   CREATE SEQUENCE public.upgradehistories_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.upgradehistories_id_seq;
       public          postgres    false    3            9           1259    666635    UpgradeHistories    TABLE     �  CREATE TABLE public."UpgradeHistories" (
    "ID" bigint DEFAULT nextval('public.upgradehistories_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "MasterDatumID" bigint NOT NULL,
    "TransactionID" text NOT NULL,
    "Msisdn" text NOT NULL,
    "AccountID" text NOT NULL,
    "OldPlanName" text NOT NULL,
    "OldPlanCode" text NOT NULL,
    "OldPlanPrice" double precision NOT NULL,
    "NewPlanName" text NOT NULL,
    "NewPlanCode" text NOT NULL,
    "NewPlanPrice" double precision NOT NULL,
    "UserID" text NOT NULL,
    "DateTime" timestamp without time zone
);
 &   DROP TABLE public."UpgradeHistories";
       public         heap    postgres    false    301    3            .           1259    660900    valueaddedservice_id_seq    SEQUENCE     �   CREATE SEQUENCE public.valueaddedservice_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.valueaddedservice_id_seq;
       public          postgres    false    3            /           1259    660901    ValueAddedService    TABLE     �  CREATE TABLE public."ValueAddedService" (
    "ID" bigint DEFAULT nextval('public.valueaddedservice_id_seq'::regclass) NOT NULL,
    "CreatedAt" timestamp(0) without time zone,
    "CreatedBy" text NOT NULL,
    "ModifiedAt" timestamp(0) without time zone,
    "ModifiedBy" text,
    "TypeID" text NOT NULL,
    "MasterDatumID" bigint NOT NULL,
    "Channel" integer NOT NULL,
    "Cost" numeric(65,30) NOT NULL
);
 '   DROP TABLE public."ValueAddedService";
       public         heap    postgres    false    302    3            0           1259    660907    cycletransaction_schema_status    VIEW     .  CREATE VIEW public.cycletransaction_schema_status AS
 SELECT ct."ID",
    ct."SchemaID",
    ct."NumberOfElements",
    ct."Total",
    ct."CycleTransactionID",
    public.getcycletransactionschemastatus(ct."CycleTransactionID", ct."SchemaID") AS "StatusID"
   FROM public."CycleTransactionSchema" ct;
 1   DROP VIEW public.cycletransaction_schema_status;
       public          postgres    false    226    226    340    226    226    226    3            1           1259    660911    cycletransaction_status    VIEW     �   CREATE VIEW public.cycletransaction_status AS
 SELECT ct."ID",
    ct."MasterDatumID",
    ct."StartDate",
    ct."EndDate",
    ct."IsCompleted",
    public.getcycletransactionstatus(ct."ID") AS "StatusID"
   FROM public."CycleTransaction" ct;
 *   DROP VIEW public.cycletransaction_status;
       public          postgres    false    224    224    224    224    224    341    3            2           1259    660915    processadapters_id_seq    SEQUENCE        CREATE SEQUENCE public.processadapters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.processadapters_id_seq;
       public          postgres    false    3            �          0    660574    AchievedEvent 
   TABLE DATA           �   COPY public."AchievedEvent" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "EventTypeID", "EventDate", "ReferenceID") FROM stdin;
    public          postgres    false    210   �      �          0    660581    AcitvityChannel 
   TABLE DATA           9   COPY public."AcitvityChannel" ("ID", "Type") FROM stdin;
    public          postgres    false    212   �      �          0    660588 
   Activation 
   TABLE DATA           �   COPY public."Activation" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "IMSI", "MSISDN", "ActivationDate", "ActivatedBy", "ActivatedByClassID", "SoldTo", "SoldToClassID", "IsEligibleForCrossSelling") FROM stdin;
    public          postgres    false    214   -      �          0    660595    ActivationExtension 
   TABLE DATA           �   COPY public."ActivationExtension" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "Email", "ActivationGeoLocation", "ActivationTagName", "SimType", "ICCID") FROM stdin;
    public          postgres    false    216   �      �          0    660602    CacheUpdatedTables 
   TABLE DATA           �   COPY public."CacheUpdatedTables" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "EntryName", "LastUpdatedTime") FROM stdin;
    public          postgres    false    218   3      �          0    660609    CrossSellingMapping 
   TABLE DATA           �   COPY public."CrossSellingMapping" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "ActivatorClassId", "RetailerToClassId") FROM stdin;
    public          postgres    false    220   P      �          0    660616    Cycle 
   TABLE DATA           z  COPY public."Cycle" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "Name", "ForeignName", "FrequencyId", "ExecutionTime", "CuttOffTime", "DayOfMonth", "LastDayOfMonth", "DayOfWeek", "Lateness", "IsEnabled", "CreationDate", "UpdatedDate", "LastRunDate", "LastAchievedCommissionableEventId", "CycleTypeId", "ChannelMemberSalesType", "ChannelMemberType") FROM stdin;
    public          postgres    false    222   m      �          0    660623    CycleTransaction 
   TABLE DATA           �   COPY public."CycleTransaction" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "CycleID", "StartDate", "EndDate", "IsCompleted", "RunDateTime", "CommissionLock", "PayoutLock") FROM stdin;
    public          postgres    false    224         �          0    660630    CycleTransactionSchema 
   TABLE DATA           �   COPY public."CycleTransactionSchema" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "SchemaID", "NumberOfElements", "Total", "CycleTransactionID") FROM stdin;
    public          postgres    false    226   �      �          0    660637 	   CycleType 
   TABLE DATA           i   COPY public."CycleType" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "Name") FROM stdin;
    public          postgres    false    228   �      �          0    660644    DataDumpsTrial 
   TABLE DATA           �   COPY public."DataDumpsTrial" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "DataDumpType", "TargetDate", "SyncStartDate", "SyncEndDate") FROM stdin;
    public          postgres    false    230         �          0    660651    DealerCommissionDataDetail 
   TABLE DATA           R  COPY public."DealerCommissionDataDetail" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "CommissionDataId", "DealerCode", "Imsi", "Msisdn", "ActivationDate", "Uidentifier", "ActivationProcessName", "CommissionMeritedClassId", "CommissionMerited", "DealerSchedulePayment", "DealerSegment", "DealerPrepaidTarget") FROM stdin;
    public          postgres    false    232   )      �          0    660658    DealerCommissionDatum 
   TABLE DATA             COPY public."DealerCommissionDatum" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "DealerCode", "TotalRecharges", "CustomerBase", "AverageRecharges", "PrepaidTarget", "PostpaidTarget", "Segment", "CommissionTransactionId", "SchemaId", "MasterDatumID") FROM stdin;
    public          postgres    false    234   F      �          0    660665    DealerCommissionExtensionDatum 
   TABLE DATA           �   COPY public."DealerCommissionExtensionDatum" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "RevenueTarget", "TotalRevenue", "ActivationTarget", "AverageAchievedTarget", "MasterDatumID") FROM stdin;
    public          postgres    false    236   c      �          0    660672 %   DealerCycleTransactionActivationDatum 
   TABLE DATA             COPY public."DealerCycleTransactionActivationDatum" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "CycleTransactionId", "DealerCode", "CommissionDataId", "ActivationOrder", "DealerSegmantId", "DealerPrepaidTarget", "DealerIsMonthlyCommission") FROM stdin;
    public          postgres    false    238   �      �          0    660679    DealerSuspension 
   TABLE DATA           �   COPY public."DealerSuspension" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "DealerCode", "SchemaId", "Reason", "IsActive", "StartDate", "EndDate") FROM stdin;
    public          postgres    false    240   �      �          0    660686 
   DumpTrials 
   TABLE DATA           h   COPY public."DumpTrials" ("ID", "TargetDate", "SyncStartDate", "SyncEndDate", "DumpTypeID") FROM stdin;
    public          postgres    false    242   �      �          0    660691    DwhdumpsTrial 
   TABLE DATA           �   COPY public."DwhdumpsTrial" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "TargetDate", "SyncStartDate", "SyncEndDate") FROM stdin;
    public          postgres    false    244   \      �          0    660698    Dwhtry 
   TABLE DATA           y   COPY public."Dwhtry" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "LastRunDate", "FileName") FROM stdin;
    public          postgres    false    246   y      �          0    660705    EarningCommissionDatum 
   TABLE DATA           �   COPY public."EarningCommissionDatum" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "DealerCode", "Amount", "SchemaId", "MasterDatumID") FROM stdin;
    public          postgres    false    248   �      �          0    660712    Element 
   TABLE DATA           J  COPY public."Element" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "Name", "ForeignName", "Weight", "IsEssential", "Rules", "SchemaId", "Ordinal", "EnableNotifications", "NotificationEventId", "NotificationMessageId", "IsHidden", "RuleBuilderData", "AllowMultiEvaluation", "MaxWeight", "UpdateReason") FROM stdin;
    public          postgres    false    250   �      �          0    660719    EvaluationResult 
   TABLE DATA           �  COPY public."EvaluationResult" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "ElementID", "SchemaID", "Amount", "CreationDate", "UpdateDate", "Dealer", "StatusID", "CycleTransactionID", "IsPaymentTransfered", "UpdatedBy", "InstantCommissionRequestID", "ReferenceId", "PayoutTransactionID", "OldAmount", "IsLocked", "LockExpiration", "ChannelMemberSalesType", "ChannelMemberType") FROM stdin;
    public          postgres    false    252   �      �          0    660726 	   EventType 
   TABLE DATA           �   COPY public."EventType" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "Name", "IsDynamicEvent", "IsActive", "Code") FROM stdin;
    public          postgres    false    254   �      �          0    660733 	   Frequency 
   TABLE DATA           i   COPY public."Frequency" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "Name") FROM stdin;
    public          postgres    false    256   N       1          0    666483    HbborderHistories 
   TABLE DATA           �   COPY public."HbborderHistories" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "OrderID", "FDN", "AccountID", "UserID", "PlanName", "PlanCode", "PlanPrice", "Datetime", "BillAccountNo") FROM stdin;
    public          postgres    false    312   �       5          0    666689    HbborderPaymentHistories 
   TABLE DATA           �   COPY public."HbborderPaymentHistories" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "TransactionId", "TransactionBillingId", "BillAccountNo", "SysCreationTime", "TransactionAmount", "SysCreationDate") FROM stdin;
    public          postgres    false    316   �       6          0    666713    HbborderPaymentHistoriesSchema 
   TABLE DATA           P  COPY public."HbborderPaymentHistoriesSchema" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "OrderID", "FDN", "PlanName", "PlanCode", "BillAccountNo", "ActivationDate", "BillDate", "TransactionAmount", "BillPaymentTransactionIds", "IsCommissionCalculated", "PlanPrice", "TotalPaidBillAmount") FROM stdin;
    public          postgres    false    317   �       �          0    660740    InstantCommissionRequest 
   TABLE DATA             COPY public."InstantCommissionRequest" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MSISDN", "IMSI", "InstantCommissionType", "RequestDetails", "EventRegistered", "Evaluated", "IsPaymentTransferred", "CreationDate", "LogId", "CommissionDataId") FROM stdin;
    public          postgres    false    258   �       �          0    660747    InstantCommissionRequestLog 
   TABLE DATA           �   COPY public."InstantCommissionRequestLog" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "InstantCommissionRequestID", "MasterDatumID", "CreationDate", "Type", "Text", "Description") FROM stdin;
    public          postgres    false    260                   0    660754    Language 
   TABLE DATA           h   COPY public."Language" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "Name") FROM stdin;
    public          postgres    false    262   �U                0    660761    Log 
   TABLE DATA           �   COPY public."Log" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "Source", "Type", "Text", "Description", "DateTime") FROM stdin;
    public          postgres    false    264   V                0    660768    MasterDatum 
   TABLE DATA           k   COPY public."MasterDatum" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "Name") FROM stdin;
    public          postgres    false    266   �X                0    660775    NotificationMessage 
   TABLE DATA           k   COPY public."NotificationMessage" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy") FROM stdin;
    public          postgres    false    268   �Y      	          0    660782    NotificationMessageText 
   TABLE DATA           �   COPY public."NotificationMessageText" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "NotificationMessageId", "LanguageId", "Text") FROM stdin;
    public          postgres    false    270   �Y                0    660789    OrderHistories 
   TABLE DATA           �   COPY public."OrderHistories" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "OrderId", "ContractId", "SoldToParty", "Plan", "OrderBy", "OrderDate", "PlanPrice") FROM stdin;
    public          postgres    false    272   �Y                0    660796    PaymentHistories 
   TABLE DATA           �   COPY public."PaymentHistories" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "PaymentId", "Total", "Vat", "PaymentDate", "ActivationId", "UserId") FROM stdin;
    public          postgres    false    274   �Y                0    660803    PaymentStatus 
   TABLE DATA           m   COPY public."PaymentStatus" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "Name") FROM stdin;
    public          postgres    false    276   Z                0    660810    PayoutTransaction 
   TABLE DATA           "  COPY public."PayoutTransaction" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "DealerCode", "SalesPersonCode", "GrossAmount", "Amount", "PaymentStatusId", "CycleTransactionID", "Payload", "CreatedDate", "LastUpdateDate", "SchemaID", "InstantCommissionRequestID") FROM stdin;
    public          postgres    false    278   �Z      -          0    666455    PostpaidHistories 
   TABLE DATA           �   COPY public."PostpaidHistories" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "OrderID", "Msisdn", "AccountID", "UserID", "PlanName", "PlanCode", "PlanPrice", "Datetime") FROM stdin;
    public          postgres    false    308   �Z      8          0    666807    PostpaidPaymentHistories 
   TABLE DATA           �   COPY public."PostpaidPaymentHistories" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "TransactionId", "TransactionBillingId", "BillAccountNo", "SysCreationTime", "TransactionAmount", "SysCreationDate") FROM stdin;
    public          postgres    false    319   �Z      :          0    666822    PostpaidPaymentHistoriesSchema 
   TABLE DATA           P  COPY public."PostpaidPaymentHistoriesSchema" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "OrderID", "FDN", "PlanName", "PlanCode", "BillAccountNo", "ActivationDate", "BillDate", "TransactionAmount", "BillPaymentTransactionIds", "IsCommissionCalculated", "PlanPrice", "TotalPaidBillAmount") FROM stdin;
    public          postgres    false    321   n[      /          0    666469    PrepaidHistories 
   TABLE DATA           �   COPY public."PrepaidHistories" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "OrderID", "Msisdn", "AccountID", "UserID", "PlanName", "PlanCode", "PlanPrice", "Datetime", "SubscrNo") FROM stdin;
    public          postgres    false    310   �[      >          0    666850    PrepaidPaymentHistories 
   TABLE DATA           �   COPY public."PrepaidPaymentHistories" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "TransactionId", "SubscrNo", "EventHour", "Amount", "EventDate") FROM stdin;
    public          postgres    false    325   �[      <          0    666836    PrepaidPaymentHistoriesSchema 
   TABLE DATA           M  COPY public."PrepaidPaymentHistoriesSchema" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "OrderID", "Msisdn", "PlanName", "PlanCode", "PlanPrice", "SubscrNo", "ActivationDate", "BillDate", "TransactionAmount", "BillPaymentTransactionIds", "IsCommissionCalculated", "TotalPaidBillAmount") FROM stdin;
    public          postgres    false    323   \                0    660817    Product 
   TABLE DATA           �   COPY public."Product" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "Name", "EventTypeID", "RefId", "SubscriptionManagmentId") FROM stdin;
    public          postgres    false    280   5\                0    660824    ProductSelling 
   TABLE DATA           �   COPY public."ProductSelling" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "TransactionId", "ReferenceId", "ActivationID", "ProductID", "Msisdn", "AccountNo", "TransactionDate", "CreationDate", "DealerCode", "DealerClassId") FROM stdin;
    public          postgres    false    282   R\                0    660831    ProductSellingException 
   TABLE DATA             COPY public."ProductSellingException" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "LogId", "TransactionId", "ReferenceId", "ActivationCommissionDataId", "ProductId", "Msisdn", "AccountNo", "TransactionDate", "CreationDate", "DealerCode", "DealerClassId") FROM stdin;
    public          postgres    false    284   o\                0    660838    Schema 
   TABLE DATA           �  COPY public."Schema" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "Name", "ForeignName", "Active", "Query", "CycleID", "CommissionMerited", "BrandId", "NotificationMessageID", "CommissionMeritedClassId", "CalculationSpecificationID", "ApplicableFrom", "ApplicableTo", "CreationDate", "ChangeLog", "LastUpdateDate", "LastUpdatedBy", "PaymentMethod", "UpdateReason", "NotificationID") FROM stdin;
    public          postgres    false    286   �\                0    660845    SchemaCalculationSpecification 
   TABLE DATA           �   COPY public."SchemaCalculationSpecification" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "Name", "BaseQuery", "SchemaHandlerType", "AssemblyPath", "ClassName", "BasePath", "SecondaryQuery") FROM stdin;
    public          postgres    false    288   �]                0    660852    SchemaDealer 
   TABLE DATA           ~   COPY public."SchemaDealer" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "SchemaID", "DealerCode") FROM stdin;
    public          postgres    false    290   	`                0    660859    SpecialNumberDatum 
   TABLE DATA           �   COPY public."SpecialNumberDatum" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "Cost", "MasterDatumID", "Channel") FROM stdin;
    public          postgres    false    292   &`      !          0    660866    Status 
   TABLE DATA           f   COPY public."Status" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "Name") FROM stdin;
    public          postgres    false    294   �`      #          0    660873    SubscriptionPlan 
   TABLE DATA           �   COPY public."SubscriptionPlan" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "TypeID", "MasterDatumID", "Cost", "Channel") FROM stdin;
    public          postgres    false    296   5a      %          0    660880    SubscriptionreFill 
   TABLE DATA           �   COPY public."SubscriptionreFill" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "MSISDN", "TimeStamp", "AccountNo", "Amount", "ReferenceNo", "Ordinal") FROM stdin;
    public          postgres    false    298   �a      '          0    660887    SystemConfiguration 
   TABLE DATA           {   COPY public."SystemConfiguration" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "Key", "Value") FROM stdin;
    public          postgres    false    300   �a      2          0    666635    UpgradeHistories 
   TABLE DATA             COPY public."UpgradeHistories" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "MasterDatumID", "TransactionID", "Msisdn", "AccountID", "OldPlanName", "OldPlanCode", "OldPlanPrice", "NewPlanName", "NewPlanCode", "NewPlanPrice", "UserID", "DateTime") FROM stdin;
    public          postgres    false    313   �a      *          0    660901    ValueAddedService 
   TABLE DATA           �   COPY public."ValueAddedService" ("ID", "CreatedAt", "CreatedBy", "ModifiedAt", "ModifiedBy", "TypeID", "MasterDatumID", "Channel", "Cost") FROM stdin;
    public          postgres    false    303   Ob      F           0    0    achievedevent_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.achievedevent_id_seq', 531107, true);
          public          postgres    false    209            G           0    0    acitvitychannel_id_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.acitvitychannel_id_seq', 3, false);
          public          postgres    false    211            H           0    0    activation_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.activation_id_seq', 6, false);
          public          postgres    false    213            I           0    0    activationextension_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.activationextension_id_seq', 6, false);
          public          postgres    false    215            J           0    0    cacheupdatedtables_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.cacheupdatedtables_id_seq', 1, false);
          public          postgres    false    217            K           0    0    crosssellingmapping_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.crosssellingmapping_id_seq', 1, false);
          public          postgres    false    219            L           0    0    cycle_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.cycle_id_seq', 31, true);
          public          postgres    false    221            M           0    0    cycletransaction_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.cycletransaction_id_seq', 2866, true);
          public          postgres    false    223            N           0    0    cycletransactionschema_id_seq    SEQUENCE SET     N   SELECT pg_catalog.setval('public.cycletransactionschema_id_seq', 4141, true);
          public          postgres    false    225            O           0    0    cycletype_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.cycletype_id_seq', 3, false);
          public          postgres    false    227            P           0    0    datadumpstrial_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.datadumpstrial_id_seq', 1, false);
          public          postgres    false    229            Q           0    0 !   dealercommissiondatadetail_id_seq    SEQUENCE SET     P   SELECT pg_catalog.setval('public.dealercommissiondatadetail_id_seq', 1, false);
          public          postgres    false    231            R           0    0    dealercommissiondatum_id_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('public.dealercommissiondatum_id_seq', 1, false);
          public          postgres    false    233            S           0    0 %   dealercommissionextensiondatum_id_seq    SEQUENCE SET     T   SELECT pg_catalog.setval('public.dealercommissionextensiondatum_id_seq', 1, false);
          public          postgres    false    235            T           0    0 ,   dealercycletransactionactivationdatum_id_seq    SEQUENCE SET     [   SELECT pg_catalog.setval('public.dealercycletransactionactivationdatum_id_seq', 1, false);
          public          postgres    false    237            U           0    0    dealersuspension_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.dealersuspension_id_seq', 1, false);
          public          postgres    false    239            V           0    0    dumptrials_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.dumptrials_id_seq', 103, true);
          public          postgres    false    241            W           0    0    dwhdumpstrial_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.dwhdumpstrial_id_seq', 1, false);
          public          postgres    false    243            X           0    0    dwhtry_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.dwhtry_id_seq', 1, false);
          public          postgres    false    245            Y           0    0    earningcommissiondatum_id_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.earningcommissiondatum_id_seq', 1, false);
          public          postgres    false    247            Z           0    0    element_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.element_id_seq', 58, true);
          public          postgres    false    249            [           0    0    evaluationresult_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.evaluationresult_id_seq', 7262, true);
          public          postgres    false    251            \           0    0    eventtype_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.eventtype_id_seq', 6, false);
          public          postgres    false    253            ]           0    0    frequency_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.frequency_id_seq', 4, false);
          public          postgres    false    255            ^           0    0    hbborderhistories_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.hbborderhistories_id_seq', 117, true);
          public          postgres    false    311            _           0    0    hbborderpaymenthistories_id_seq    SEQUENCE SET     R   SELECT pg_catalog.setval('public.hbborderpaymenthistories_id_seq', 596158, true);
          public          postgres    false    314            `           0    0 %   hbborderpaymenthistoriesschema_id_seq    SEQUENCE SET     X   SELECT pg_catalog.setval('public.hbborderpaymenthistoriesschema_id_seq', 232588, true);
          public          postgres    false    315            a           0    0    instantcommissionrequest_id_seq    SEQUENCE SET     P   SELECT pg_catalog.setval('public.instantcommissionrequest_id_seq', 8862, true);
          public          postgres    false    257            b           0    0 "   instantcommissionrequestlog_id_seq    SEQUENCE SET     T   SELECT pg_catalog.setval('public.instantcommissionrequestlog_id_seq', 30186, true);
          public          postgres    false    259            c           0    0    language_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.language_id_seq', 3, false);
          public          postgres    false    261            d           0    0 
   log_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.log_id_seq', 81815, true);
          public          postgres    false    263            e           0    0    masterdatum_id_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.masterdatum_id_seq', 903564, true);
          public          postgres    false    265            f           0    0    notificationmessage_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.notificationmessage_id_seq', 30, true);
          public          postgres    false    267            g           0    0    notificationmessagetext_id_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('public.notificationmessagetext_id_seq', 54, true);
          public          postgres    false    269            h           0    0    orderhistories_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.orderhistories_id_seq', 3496, true);
          public          postgres    false    271            i           0    0    paymenthistories_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.paymenthistories_id_seq', 265, true);
          public          postgres    false    273            j           0    0    paymentstatus_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.paymentstatus_id_seq', 10, false);
          public          postgres    false    275            k           0    0    payouttransaction_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.payouttransaction_id_seq', 6268, true);
          public          postgres    false    277            l           0    0    postpaidhistories_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.postpaidhistories_id_seq', 21, true);
          public          postgres    false    307            m           0    0    postpaidpaymenthistories_id_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('public.postpaidpaymenthistories_id_seq', 3, true);
          public          postgres    false    318            n           0    0 %   postpaidpaymenthistoriesschema_id_seq    SEQUENCE SET     T   SELECT pg_catalog.setval('public.postpaidpaymenthistoriesschema_id_seq', 1, false);
          public          postgres    false    320            o           0    0    prepaidhistories_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.prepaidhistories_id_seq', 58, true);
          public          postgres    false    309            p           0    0    prepaidpaymenthistories_id_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.prepaidpaymenthistories_id_seq', 3, true);
          public          postgres    false    324            q           0    0 $   prepaidpaymenthistoriesschema_id_seq    SEQUENCE SET     S   SELECT pg_catalog.setval('public.prepaidpaymenthistoriesschema_id_seq', 1, false);
          public          postgres    false    322            r           0    0    processadapters_id_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.processadapters_id_seq', 1, false);
          public          postgres    false    306            s           0    0    product_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.product_id_seq', 1, false);
          public          postgres    false    279            t           0    0    productselling_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.productselling_id_seq', 1, false);
          public          postgres    false    281            u           0    0    productsellingexception_id_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('public.productsellingexception_id_seq', 1, false);
          public          postgres    false    283            v           0    0    schema_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.schema_id_seq', 35, true);
          public          postgres    false    285            w           0    0 %   schemacalculationspecification_id_seq    SEQUENCE SET     S   SELECT pg_catalog.setval('public.schemacalculationspecification_id_seq', 2, true);
          public          postgres    false    287            x           0    0    schemadealer_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.schemadealer_id_seq', 1, false);
          public          postgres    false    289            y           0    0    specialnumberdatum_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.specialnumberdatum_id_seq', 6, false);
          public          postgres    false    291            z           0    0    status_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.status_id_seq', 11, false);
          public          postgres    false    293            {           0    0    subscriptionplan_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.subscriptionplan_id_seq', 6, false);
          public          postgres    false    295            |           0    0    subscriptionrefill_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.subscriptionrefill_id_seq', 1, false);
          public          postgres    false    297            }           0    0    systemconfiguration_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.systemconfiguration_id_seq', 1, false);
          public          postgres    false    299            ~           0    0    upgradehistories_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.upgradehistories_id_seq', 904, true);
          public          postgres    false    301                       0    0    valueaddedservice_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.valueaddedservice_id_seq', 1, false);
          public          postgres    false    302            �           2606    660917    DumpTrials DumpTrials_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY public."DumpTrials"
    ADD CONSTRAINT "DumpTrials_pkey" PRIMARY KEY ("ID");
 H   ALTER TABLE ONLY public."DumpTrials" DROP CONSTRAINT "DumpTrials_pkey";
       public            postgres    false    242            $           2606    666490 (   HbborderHistories HbborderHistories_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public."HbborderHistories"
    ADD CONSTRAINT "HbborderHistories_pkey" PRIMARY KEY ("ID");
 V   ALTER TABLE ONLY public."HbborderHistories" DROP CONSTRAINT "HbborderHistories_pkey";
       public            postgres    false    312            *           2606    666720 B   HbborderPaymentHistoriesSchema HbborderPaymentHistoriesSchema_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public."HbborderPaymentHistoriesSchema"
    ADD CONSTRAINT "HbborderPaymentHistoriesSchema_pkey" PRIMARY KEY ("ID");
 p   ALTER TABLE ONLY public."HbborderPaymentHistoriesSchema" DROP CONSTRAINT "HbborderPaymentHistoriesSchema_pkey";
       public            postgres    false    317            (           2606    666696 6   HbborderPaymentHistories HbborderPaymentHistories_pkey 
   CONSTRAINT     z   ALTER TABLE ONLY public."HbborderPaymentHistories"
    ADD CONSTRAINT "HbborderPaymentHistories_pkey" PRIMARY KEY ("ID");
 d   ALTER TABLE ONLY public."HbborderPaymentHistories" DROP CONSTRAINT "HbborderPaymentHistories_pkey";
       public            postgres    false    316                        2606    660919 "   OrderHistories OrderHistories_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public."OrderHistories"
    ADD CONSTRAINT "OrderHistories_pkey" PRIMARY KEY ("ID");
 P   ALTER TABLE ONLY public."OrderHistories" DROP CONSTRAINT "OrderHistories_pkey";
       public            postgres    false    272            �           2606    660921    AchievedEvent PRIMARY 
   CONSTRAINT     Y   ALTER TABLE ONLY public."AchievedEvent"
    ADD CONSTRAINT "PRIMARY" PRIMARY KEY ("ID");
 C   ALTER TABLE ONLY public."AchievedEvent" DROP CONSTRAINT "PRIMARY";
       public            postgres    false    210            �           2606    660923    AcitvityChannel PRIMARY00000 
   CONSTRAINT     `   ALTER TABLE ONLY public."AcitvityChannel"
    ADD CONSTRAINT "PRIMARY00000" PRIMARY KEY ("ID");
 J   ALTER TABLE ONLY public."AcitvityChannel" DROP CONSTRAINT "PRIMARY00000";
       public            postgres    false    212            �           2606    660925    Activation PRIMARY00001 
   CONSTRAINT     [   ALTER TABLE ONLY public."Activation"
    ADD CONSTRAINT "PRIMARY00001" PRIMARY KEY ("ID");
 E   ALTER TABLE ONLY public."Activation" DROP CONSTRAINT "PRIMARY00001";
       public            postgres    false    214            �           2606    660927     ActivationExtension PRIMARY00002 
   CONSTRAINT     d   ALTER TABLE ONLY public."ActivationExtension"
    ADD CONSTRAINT "PRIMARY00002" PRIMARY KEY ("ID");
 N   ALTER TABLE ONLY public."ActivationExtension" DROP CONSTRAINT "PRIMARY00002";
       public            postgres    false    216            �           2606    660929    CacheUpdatedTables PRIMARY00003 
   CONSTRAINT     c   ALTER TABLE ONLY public."CacheUpdatedTables"
    ADD CONSTRAINT "PRIMARY00003" PRIMARY KEY ("ID");
 M   ALTER TABLE ONLY public."CacheUpdatedTables" DROP CONSTRAINT "PRIMARY00003";
       public            postgres    false    218            �           2606    660931     CrossSellingMapping PRIMARY00004 
   CONSTRAINT     d   ALTER TABLE ONLY public."CrossSellingMapping"
    ADD CONSTRAINT "PRIMARY00004" PRIMARY KEY ("ID");
 N   ALTER TABLE ONLY public."CrossSellingMapping" DROP CONSTRAINT "PRIMARY00004";
       public            postgres    false    220            �           2606    660933    Cycle PRIMARY00005 
   CONSTRAINT     V   ALTER TABLE ONLY public."Cycle"
    ADD CONSTRAINT "PRIMARY00005" PRIMARY KEY ("ID");
 @   ALTER TABLE ONLY public."Cycle" DROP CONSTRAINT "PRIMARY00005";
       public            postgres    false    222            �           2606    660935    CycleTransaction PRIMARY00006 
   CONSTRAINT     a   ALTER TABLE ONLY public."CycleTransaction"
    ADD CONSTRAINT "PRIMARY00006" PRIMARY KEY ("ID");
 K   ALTER TABLE ONLY public."CycleTransaction" DROP CONSTRAINT "PRIMARY00006";
       public            postgres    false    224            �           2606    660937 #   CycleTransactionSchema PRIMARY00007 
   CONSTRAINT     g   ALTER TABLE ONLY public."CycleTransactionSchema"
    ADD CONSTRAINT "PRIMARY00007" PRIMARY KEY ("ID");
 Q   ALTER TABLE ONLY public."CycleTransactionSchema" DROP CONSTRAINT "PRIMARY00007";
       public            postgres    false    226            �           2606    660939    CycleType PRIMARY00008 
   CONSTRAINT     Z   ALTER TABLE ONLY public."CycleType"
    ADD CONSTRAINT "PRIMARY00008" PRIMARY KEY ("ID");
 D   ALTER TABLE ONLY public."CycleType" DROP CONSTRAINT "PRIMARY00008";
       public            postgres    false    228            �           2606    660941    DataDumpsTrial PRIMARY00009 
   CONSTRAINT     _   ALTER TABLE ONLY public."DataDumpsTrial"
    ADD CONSTRAINT "PRIMARY00009" PRIMARY KEY ("ID");
 I   ALTER TABLE ONLY public."DataDumpsTrial" DROP CONSTRAINT "PRIMARY00009";
       public            postgres    false    230            �           2606    660943 '   DealerCommissionDataDetail PRIMARY00010 
   CONSTRAINT     k   ALTER TABLE ONLY public."DealerCommissionDataDetail"
    ADD CONSTRAINT "PRIMARY00010" PRIMARY KEY ("ID");
 U   ALTER TABLE ONLY public."DealerCommissionDataDetail" DROP CONSTRAINT "PRIMARY00010";
       public            postgres    false    232            �           2606    660945 "   DealerCommissionDatum PRIMARY00011 
   CONSTRAINT     f   ALTER TABLE ONLY public."DealerCommissionDatum"
    ADD CONSTRAINT "PRIMARY00011" PRIMARY KEY ("ID");
 P   ALTER TABLE ONLY public."DealerCommissionDatum" DROP CONSTRAINT "PRIMARY00011";
       public            postgres    false    234            �           2606    660947 +   DealerCommissionExtensionDatum PRIMARY00012 
   CONSTRAINT     o   ALTER TABLE ONLY public."DealerCommissionExtensionDatum"
    ADD CONSTRAINT "PRIMARY00012" PRIMARY KEY ("ID");
 Y   ALTER TABLE ONLY public."DealerCommissionExtensionDatum" DROP CONSTRAINT "PRIMARY00012";
       public            postgres    false    236            �           2606    660949 2   DealerCycleTransactionActivationDatum PRIMARY00013 
   CONSTRAINT     v   ALTER TABLE ONLY public."DealerCycleTransactionActivationDatum"
    ADD CONSTRAINT "PRIMARY00013" PRIMARY KEY ("ID");
 `   ALTER TABLE ONLY public."DealerCycleTransactionActivationDatum" DROP CONSTRAINT "PRIMARY00013";
       public            postgres    false    238            �           2606    660951    DealerSuspension PRIMARY00014 
   CONSTRAINT     a   ALTER TABLE ONLY public."DealerSuspension"
    ADD CONSTRAINT "PRIMARY00014" PRIMARY KEY ("ID");
 K   ALTER TABLE ONLY public."DealerSuspension" DROP CONSTRAINT "PRIMARY00014";
       public            postgres    false    240            �           2606    660953    DwhdumpsTrial PRIMARY00015 
   CONSTRAINT     ^   ALTER TABLE ONLY public."DwhdumpsTrial"
    ADD CONSTRAINT "PRIMARY00015" PRIMARY KEY ("ID");
 H   ALTER TABLE ONLY public."DwhdumpsTrial" DROP CONSTRAINT "PRIMARY00015";
       public            postgres    false    244            �           2606    660955    Dwhtry PRIMARY00016 
   CONSTRAINT     W   ALTER TABLE ONLY public."Dwhtry"
    ADD CONSTRAINT "PRIMARY00016" PRIMARY KEY ("ID");
 A   ALTER TABLE ONLY public."Dwhtry" DROP CONSTRAINT "PRIMARY00016";
       public            postgres    false    246            �           2606    660957 #   EarningCommissionDatum PRIMARY00017 
   CONSTRAINT     g   ALTER TABLE ONLY public."EarningCommissionDatum"
    ADD CONSTRAINT "PRIMARY00017" PRIMARY KEY ("ID");
 Q   ALTER TABLE ONLY public."EarningCommissionDatum" DROP CONSTRAINT "PRIMARY00017";
       public            postgres    false    248            �           2606    660959    Element PRIMARY00018 
   CONSTRAINT     X   ALTER TABLE ONLY public."Element"
    ADD CONSTRAINT "PRIMARY00018" PRIMARY KEY ("ID");
 B   ALTER TABLE ONLY public."Element" DROP CONSTRAINT "PRIMARY00018";
       public            postgres    false    250            �           2606    660961    EvaluationResult PRIMARY00019 
   CONSTRAINT     a   ALTER TABLE ONLY public."EvaluationResult"
    ADD CONSTRAINT "PRIMARY00019" PRIMARY KEY ("ID");
 K   ALTER TABLE ONLY public."EvaluationResult" DROP CONSTRAINT "PRIMARY00019";
       public            postgres    false    252            �           2606    660963    EventType PRIMARY00020 
   CONSTRAINT     Z   ALTER TABLE ONLY public."EventType"
    ADD CONSTRAINT "PRIMARY00020" PRIMARY KEY ("ID");
 D   ALTER TABLE ONLY public."EventType" DROP CONSTRAINT "PRIMARY00020";
       public            postgres    false    254            �           2606    660965    Frequency PRIMARY00021 
   CONSTRAINT     Z   ALTER TABLE ONLY public."Frequency"
    ADD CONSTRAINT "PRIMARY00021" PRIMARY KEY ("ID");
 D   ALTER TABLE ONLY public."Frequency" DROP CONSTRAINT "PRIMARY00021";
       public            postgres    false    256            �           2606    660967 %   InstantCommissionRequest PRIMARY00022 
   CONSTRAINT     i   ALTER TABLE ONLY public."InstantCommissionRequest"
    ADD CONSTRAINT "PRIMARY00022" PRIMARY KEY ("ID");
 S   ALTER TABLE ONLY public."InstantCommissionRequest" DROP CONSTRAINT "PRIMARY00022";
       public            postgres    false    258            �           2606    660969 (   InstantCommissionRequestLog PRIMARY00023 
   CONSTRAINT     l   ALTER TABLE ONLY public."InstantCommissionRequestLog"
    ADD CONSTRAINT "PRIMARY00023" PRIMARY KEY ("ID");
 V   ALTER TABLE ONLY public."InstantCommissionRequestLog" DROP CONSTRAINT "PRIMARY00023";
       public            postgres    false    260            �           2606    660971    Language PRIMARY00024 
   CONSTRAINT     Y   ALTER TABLE ONLY public."Language"
    ADD CONSTRAINT "PRIMARY00024" PRIMARY KEY ("ID");
 C   ALTER TABLE ONLY public."Language" DROP CONSTRAINT "PRIMARY00024";
       public            postgres    false    262            �           2606    660973    Log PRIMARY00025 
   CONSTRAINT     T   ALTER TABLE ONLY public."Log"
    ADD CONSTRAINT "PRIMARY00025" PRIMARY KEY ("ID");
 >   ALTER TABLE ONLY public."Log" DROP CONSTRAINT "PRIMARY00025";
       public            postgres    false    264            �           2606    660975    MasterDatum PRIMARY00026 
   CONSTRAINT     \   ALTER TABLE ONLY public."MasterDatum"
    ADD CONSTRAINT "PRIMARY00026" PRIMARY KEY ("ID");
 F   ALTER TABLE ONLY public."MasterDatum" DROP CONSTRAINT "PRIMARY00026";
       public            postgres    false    266            �           2606    660977     NotificationMessage PRIMARY00027 
   CONSTRAINT     d   ALTER TABLE ONLY public."NotificationMessage"
    ADD CONSTRAINT "PRIMARY00027" PRIMARY KEY ("ID");
 N   ALTER TABLE ONLY public."NotificationMessage" DROP CONSTRAINT "PRIMARY00027";
       public            postgres    false    268            �           2606    660979 $   NotificationMessageText PRIMARY00028 
   CONSTRAINT     h   ALTER TABLE ONLY public."NotificationMessageText"
    ADD CONSTRAINT "PRIMARY00028" PRIMARY KEY ("ID");
 R   ALTER TABLE ONLY public."NotificationMessageText" DROP CONSTRAINT "PRIMARY00028";
       public            postgres    false    270                       2606    660981    PaymentStatus PRIMARY00029 
   CONSTRAINT     ^   ALTER TABLE ONLY public."PaymentStatus"
    ADD CONSTRAINT "PRIMARY00029" PRIMARY KEY ("ID");
 H   ALTER TABLE ONLY public."PaymentStatus" DROP CONSTRAINT "PRIMARY00029";
       public            postgres    false    276                       2606    660983    PayoutTransaction PRIMARY00030 
   CONSTRAINT     b   ALTER TABLE ONLY public."PayoutTransaction"
    ADD CONSTRAINT "PRIMARY00030" PRIMARY KEY ("ID");
 L   ALTER TABLE ONLY public."PayoutTransaction" DROP CONSTRAINT "PRIMARY00030";
       public            postgres    false    278                       2606    660985    Product PRIMARY00031 
   CONSTRAINT     X   ALTER TABLE ONLY public."Product"
    ADD CONSTRAINT "PRIMARY00031" PRIMARY KEY ("ID");
 B   ALTER TABLE ONLY public."Product" DROP CONSTRAINT "PRIMARY00031";
       public            postgres    false    280            
           2606    660987    ProductSelling PRIMARY00032 
   CONSTRAINT     _   ALTER TABLE ONLY public."ProductSelling"
    ADD CONSTRAINT "PRIMARY00032" PRIMARY KEY ("ID");
 I   ALTER TABLE ONLY public."ProductSelling" DROP CONSTRAINT "PRIMARY00032";
       public            postgres    false    282                       2606    660989 $   ProductSellingException PRIMARY00033 
   CONSTRAINT     h   ALTER TABLE ONLY public."ProductSellingException"
    ADD CONSTRAINT "PRIMARY00033" PRIMARY KEY ("ID");
 R   ALTER TABLE ONLY public."ProductSellingException" DROP CONSTRAINT "PRIMARY00033";
       public            postgres    false    284                       2606    660991    Schema PRIMARY00034 
   CONSTRAINT     W   ALTER TABLE ONLY public."Schema"
    ADD CONSTRAINT "PRIMARY00034" PRIMARY KEY ("ID");
 A   ALTER TABLE ONLY public."Schema" DROP CONSTRAINT "PRIMARY00034";
       public            postgres    false    286                       2606    660993 +   SchemaCalculationSpecification PRIMARY00035 
   CONSTRAINT     o   ALTER TABLE ONLY public."SchemaCalculationSpecification"
    ADD CONSTRAINT "PRIMARY00035" PRIMARY KEY ("ID");
 Y   ALTER TABLE ONLY public."SchemaCalculationSpecification" DROP CONSTRAINT "PRIMARY00035";
       public            postgres    false    288                       2606    660995    SchemaDealer PRIMARY00036 
   CONSTRAINT     ]   ALTER TABLE ONLY public."SchemaDealer"
    ADD CONSTRAINT "PRIMARY00036" PRIMARY KEY ("ID");
 G   ALTER TABLE ONLY public."SchemaDealer" DROP CONSTRAINT "PRIMARY00036";
       public            postgres    false    290                       2606    660997    SpecialNumberDatum PRIMARY00037 
   CONSTRAINT     c   ALTER TABLE ONLY public."SpecialNumberDatum"
    ADD CONSTRAINT "PRIMARY00037" PRIMARY KEY ("ID");
 M   ALTER TABLE ONLY public."SpecialNumberDatum" DROP CONSTRAINT "PRIMARY00037";
       public            postgres    false    292                       2606    660999    Status PRIMARY00038 
   CONSTRAINT     W   ALTER TABLE ONLY public."Status"
    ADD CONSTRAINT "PRIMARY00038" PRIMARY KEY ("ID");
 A   ALTER TABLE ONLY public."Status" DROP CONSTRAINT "PRIMARY00038";
       public            postgres    false    294                       2606    661001    SubscriptionPlan PRIMARY00039 
   CONSTRAINT     a   ALTER TABLE ONLY public."SubscriptionPlan"
    ADD CONSTRAINT "PRIMARY00039" PRIMARY KEY ("ID");
 K   ALTER TABLE ONLY public."SubscriptionPlan" DROP CONSTRAINT "PRIMARY00039";
       public            postgres    false    296                       2606    661003    SubscriptionreFill PRIMARY00040 
   CONSTRAINT     c   ALTER TABLE ONLY public."SubscriptionreFill"
    ADD CONSTRAINT "PRIMARY00040" PRIMARY KEY ("ID");
 M   ALTER TABLE ONLY public."SubscriptionreFill" DROP CONSTRAINT "PRIMARY00040";
       public            postgres    false    298                       2606    661005     SystemConfiguration PRIMARY00041 
   CONSTRAINT     d   ALTER TABLE ONLY public."SystemConfiguration"
    ADD CONSTRAINT "PRIMARY00041" PRIMARY KEY ("ID");
 N   ALTER TABLE ONLY public."SystemConfiguration" DROP CONSTRAINT "PRIMARY00041";
       public            postgres    false    300                       2606    661007    ValueAddedService PRIMARY00042 
   CONSTRAINT     b   ALTER TABLE ONLY public."ValueAddedService"
    ADD CONSTRAINT "PRIMARY00042" PRIMARY KEY ("ID");
 L   ALTER TABLE ONLY public."ValueAddedService" DROP CONSTRAINT "PRIMARY00042";
       public            postgres    false    303                       2606    661009 &   PaymentHistories PaymentHistories_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public."PaymentHistories"
    ADD CONSTRAINT "PaymentHistories_pkey" PRIMARY KEY ("ID");
 T   ALTER TABLE ONLY public."PaymentHistories" DROP CONSTRAINT "PaymentHistories_pkey";
       public            postgres    false    274                        2606    666462 (   PostpaidHistories PostpaidHistories_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY public."PostpaidHistories"
    ADD CONSTRAINT "PostpaidHistories_pkey" PRIMARY KEY ("ID");
 V   ALTER TABLE ONLY public."PostpaidHistories" DROP CONSTRAINT "PostpaidHistories_pkey";
       public            postgres    false    308            .           2606    666829 B   PostpaidPaymentHistoriesSchema PostpaidPaymentHistoriesSchema_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public."PostpaidPaymentHistoriesSchema"
    ADD CONSTRAINT "PostpaidPaymentHistoriesSchema_pkey" PRIMARY KEY ("ID");
 p   ALTER TABLE ONLY public."PostpaidPaymentHistoriesSchema" DROP CONSTRAINT "PostpaidPaymentHistoriesSchema_pkey";
       public            postgres    false    321            ,           2606    666814 6   PostpaidPaymentHistories PostpaidPaymentHistories_pkey 
   CONSTRAINT     z   ALTER TABLE ONLY public."PostpaidPaymentHistories"
    ADD CONSTRAINT "PostpaidPaymentHistories_pkey" PRIMARY KEY ("ID");
 d   ALTER TABLE ONLY public."PostpaidPaymentHistories" DROP CONSTRAINT "PostpaidPaymentHistories_pkey";
       public            postgres    false    319            "           2606    666476 &   PrepaidHistories PrepaidHistories_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public."PrepaidHistories"
    ADD CONSTRAINT "PrepaidHistories_pkey" PRIMARY KEY ("ID");
 T   ALTER TABLE ONLY public."PrepaidHistories" DROP CONSTRAINT "PrepaidHistories_pkey";
       public            postgres    false    310            0           2606    666843 @   PrepaidPaymentHistoriesSchema PrepaidPaymentHistoriesSchema_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public."PrepaidPaymentHistoriesSchema"
    ADD CONSTRAINT "PrepaidPaymentHistoriesSchema_pkey" PRIMARY KEY ("ID");
 n   ALTER TABLE ONLY public."PrepaidPaymentHistoriesSchema" DROP CONSTRAINT "PrepaidPaymentHistoriesSchema_pkey";
       public            postgres    false    323            2           2606    666857 4   PrepaidPaymentHistories PrepaidPaymentHistories_pkey 
   CONSTRAINT     x   ALTER TABLE ONLY public."PrepaidPaymentHistories"
    ADD CONSTRAINT "PrepaidPaymentHistories_pkey" PRIMARY KEY ("ID");
 b   ALTER TABLE ONLY public."PrepaidPaymentHistories" DROP CONSTRAINT "PrepaidPaymentHistories_pkey";
       public            postgres    false    325            &           2606    666642 &   UpgradeHistories UpgradeHistories_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY public."UpgradeHistories"
    ADD CONSTRAINT "UpgradeHistories_pkey" PRIMARY KEY ("ID");
 T   ALTER TABLE ONLY public."UpgradeHistories" DROP CONSTRAINT "UpgradeHistories_pkey";
       public            postgres    false    313            7           2606    666491 &   HbborderHistories hbborderhistories_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public."HbborderHistories"
    ADD CONSTRAINT hbborderhistories_fk FOREIGN KEY ("MasterDatumID") REFERENCES public."MasterDatum"("ID");
 R   ALTER TABLE ONLY public."HbborderHistories" DROP CONSTRAINT hbborderhistories_fk;
       public          postgres    false    312    3578    266            9           2606    666697 4   HbborderPaymentHistories hbborderpaymenthistories_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public."HbborderPaymentHistories"
    ADD CONSTRAINT hbborderpaymenthistories_fk FOREIGN KEY ("MasterDatumID") REFERENCES public."MasterDatum"("ID");
 `   ALTER TABLE ONLY public."HbborderPaymentHistories" DROP CONSTRAINT hbborderpaymenthistories_fk;
       public          postgres    false    3578    266    316            :           2606    666721 @   HbborderPaymentHistoriesSchema hbborderpaymenthistoriesschema_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public."HbborderPaymentHistoriesSchema"
    ADD CONSTRAINT hbborderpaymenthistoriesschema_fk FOREIGN KEY ("MasterDatumID") REFERENCES public."MasterDatum"("ID");
 l   ALTER TABLE ONLY public."HbborderPaymentHistoriesSchema" DROP CONSTRAINT hbborderpaymenthistoriesschema_fk;
       public          postgres    false    266    317    3578            3           2606    661012     OrderHistories orderhistories_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public."OrderHistories"
    ADD CONSTRAINT orderhistories_fk FOREIGN KEY ("MasterDatumID") REFERENCES public."MasterDatum"("ID");
 L   ALTER TABLE ONLY public."OrderHistories" DROP CONSTRAINT orderhistories_fk;
       public          postgres    false    272    3578    266            4           2606    661017 $   PaymentHistories paymenthistories_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public."PaymentHistories"
    ADD CONSTRAINT paymenthistories_fk FOREIGN KEY ("MasterDatumID") REFERENCES public."MasterDatum"("ID");
 P   ALTER TABLE ONLY public."PaymentHistories" DROP CONSTRAINT paymenthistories_fk;
       public          postgres    false    3578    274    266            5           2606    666463 &   PostpaidHistories postpaidhistories_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public."PostpaidHistories"
    ADD CONSTRAINT postpaidhistories_fk FOREIGN KEY ("MasterDatumID") REFERENCES public."MasterDatum"("ID");
 R   ALTER TABLE ONLY public."PostpaidHistories" DROP CONSTRAINT postpaidhistories_fk;
       public          postgres    false    266    3578    308            ;           2606    666815 4   PostpaidPaymentHistories postpaidpaymenthistories_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public."PostpaidPaymentHistories"
    ADD CONSTRAINT postpaidpaymenthistories_fk FOREIGN KEY ("MasterDatumID") REFERENCES public."MasterDatum"("ID");
 `   ALTER TABLE ONLY public."PostpaidPaymentHistories" DROP CONSTRAINT postpaidpaymenthistories_fk;
       public          postgres    false    319    3578    266            6           2606    666477 $   PrepaidHistories prepaidhistories_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public."PrepaidHistories"
    ADD CONSTRAINT prepaidhistories_fk FOREIGN KEY ("MasterDatumID") REFERENCES public."MasterDatum"("ID");
 P   ALTER TABLE ONLY public."PrepaidHistories" DROP CONSTRAINT prepaidhistories_fk;
       public          postgres    false    266    310    3578            >           2606    666858 2   PrepaidPaymentHistories prepaidpaymenthistories_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public."PrepaidPaymentHistories"
    ADD CONSTRAINT prepaidpaymenthistories_fk FOREIGN KEY ("MasterDatumID") REFERENCES public."MasterDatum"("ID");
 ^   ALTER TABLE ONLY public."PrepaidPaymentHistories" DROP CONSTRAINT prepaidpaymenthistories_fk;
       public          postgres    false    3578    266    325            =           2606    666844 >   PrepaidPaymentHistoriesSchema prepaidpaymenthistoriesschema_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public."PrepaidPaymentHistoriesSchema"
    ADD CONSTRAINT prepaidpaymenthistoriesschema_fk FOREIGN KEY ("MasterDatumID") REFERENCES public."MasterDatum"("ID");
 j   ALTER TABLE ONLY public."PrepaidPaymentHistoriesSchema" DROP CONSTRAINT prepaidpaymenthistoriesschema_fk;
       public          postgres    false    266    3578    323            <           2606    666830 @   PostpaidPaymentHistoriesSchema psotpaidpaymenthistoriesschema_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public."PostpaidPaymentHistoriesSchema"
    ADD CONSTRAINT psotpaidpaymenthistoriesschema_fk FOREIGN KEY ("MasterDatumID") REFERENCES public."MasterDatum"("ID");
 l   ALTER TABLE ONLY public."PostpaidPaymentHistoriesSchema" DROP CONSTRAINT psotpaidpaymenthistoriesschema_fk;
       public          postgres    false    266    3578    321            8           2606    666643 $   UpgradeHistories upgradehistories_fk    FK CONSTRAINT     �   ALTER TABLE ONLY public."UpgradeHistories"
    ADD CONSTRAINT upgradehistories_fk FOREIGN KEY ("MasterDatumID") REFERENCES public."MasterDatum"("ID");
 P   ALTER TABLE ONLY public."UpgradeHistories" DROP CONSTRAINT upgradehistories_fk;
       public          postgres    false    313    266    3578            �   U   x�356440�4202�50�54V04�20�20��,.I���!KcS3cNCC�R 2T0 *!�.S�A�X2�b�	�b���� 7r      �   $   x�3�N�IsN,J�2�tIM�I-r,(������ v��      �   f   x�U�+�@DQ]�
6 ���4i���`�Hc�=�TJݜ!����ܱiЈ���a��ed+`�&��1�P׽���]W���w\BK����Ͽ�7��eH)�J�"5      �   �   x�3�4202�50�52Q04�20�2���,.I���!Β����������\N������hJjbNjg^~QnbNqf.���������%�)�dsC3+c3+SST�M�f�cm�0��ps��1z\\\ �85�      �      x������ � �      �      x������ � �      �     x����n�0���)x��I ��zZ'��z��uH�Z.�}C��r@�"��c���!G�q��\���rV��`.��9���d�ּ��ل`���<���i���by�u
@��*�:W���r����՝i_�f�9�͙��<4,f��JJ�e��;��5��lC���d��h2�T��ܵk-�>:k���Ϧ��_s�#�6,��UET� �	��' E�I�ň�����뇫ׁ�#�/�@E�*���zxK��Z	�c      �      x������ � �      �      x������ � �      �   C   x�3�4202�50�52Q04�21�22��,.I������ԔҜ�.#��\Rs�R�b���� -B1      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �      x������ � �      �   �   x����	�0E��)����ñ�!:A���r(u��ב8�\��`.�{|�7k41�7KF�c�,إԜW'�Ys��$�;��U&&p�! �G؞c�>X�L�!�Ys�0t�.i��VWs=a�"�j�#�={��P��eja�)��S�      �      x������ � �      �      x������ � �      �      x������ � �      �   �  x��ms�J�_'���Dyd�s+����N�$���}A��� ��I�[�ݷ5���06ɿj*����������$H� ��'膢j��n�dt��-�����3��bڳ�]oHF�g���l�#�~��uds���-���bC�9��ܾ�<u�I08[�o�~��PkpC�r�s24�-���W��K��<k̎��X4���?x�9"��t�o��?���l��6�����\���;j�X��)	B��j��]1���}�����{p�E/���|�|3w��g��{oB��'4๮G/�L;<�h��<���-�.Ι�bN}~y����ӷ�����:����CkW1f�m�xۖ��6�/n��[��Mo��3�{���:�?<bĻ��b �u���ީC���1����y��~��d�hO;��'��ɦ4���N���L<�q�$�L���Nm��O2�w����i��<��R��W�d�su�qMA��i�s�Y0�%�ћ`�r�}�H|#/]�t�葴��=l����Hp��_�Ko\�H�C�Ok\3�	�Rڐ�0ic��uP����4�:���
�鍍�f�����d�؈�W'���!��k7=�3����k����h�C�sch=��վ�HLMk�t*
�5�7(Ǥ(�ۍv��~� n7L�_���e��t3S�#	�'\3\�_񻀎l��F�H���G��ܜ��t"YO��ܵ��11�Ff�JˬP'zQ�>�?�֓�hC�sܟ9G"s���s׵��0��u%#A���I�7���O�B��jeLG/&~���$�쀒2��R~�౪�_L{�/vM�k�[�Z$A��Y��OG�4�EY��ѿ�����Q�ㄺVQ��7��-�;l��Z�-K���j����z�v��o�'�����̧w��������>r��A�.�����l1��NO�tA�	wGl:%NO�g�8S���g��]���&���ᄿ5�'r幣����Y�.���{f��r���_��?��L��&�!�����	�r�g��Y�Ԋ����.�m/!�z^�-�������tz�b%�m�Mt!J������5�z%�o1�Ua5s)�����\v]?���h'�i<G�y/2��`"���s � �� �K�/��d/�F�����K�/�����"}ɠ�"BAܥ|��e=�� ���ۺ�cⲼ��$�JV֒6P�e-�XֲeHmC��Y�/�tj~礷_��D.2W.r�L�9}杳=R�������-���(�����(������2R�$L�7P�f�%X���,y���)��{Ι�!n(�L�o.���ϡ|����Ӧ[�7�!}����wx�weB�^x$�Qà��WH�f���W����6��c�(�sJ�#���^��f,�CJq]޸�ҥ�H�XÅ�-�Q�������*��h�$�fԵ@�f�/�)}�^-22�tN�$� 58��k�&��7*sq6��"Q{+���X��4[9�4NTE7!N�/-�Zޙ�.�
lR��o�o�o�x!*��7����֞J�TR���-�����C��"��$��z�]��؁�6ψ� �;��Ōq-8�=D� 2q(�@ax��9)a֜���j�s���N!h����e�|H{��@��Ҿ�P�I{�@�������Պ��2����㙪�j�R�
�2F���$adp��.e,�,���-Ds׳3b�U��x���ge�
�p2z$�͠k�[��~��<��w(y�W��XvP����)_ALr�wznbGigZT?\Y�5��X5"��72�g�=����c\��L�T�&�yF���q��@YΦ����Q����	FY�:��攴�e9�hd�v��v��\q^=�<��fͨ.>Eť:�aJuVhwIe-����^Y��v���������;����U�N/Rl����ݔw�e���e�PR�O����u��Ҏ}���N�et�u�7���#�XV�݉L+7+��O����O��i�w�J�w�J'�U0D!�ݩ]{�sJ�/T��WWT���oQE�1l������[T�G���O�z0:��U����l�5f��٨)i�3xf�l�NG��sJZ�g6��BpW$�c�U���w���Ł���R����vړ��w5/S�3�tQD��M��J^�*�� 7� Z�n+��q�Ǫ�Dܢ�(q�����y�@@@@���r������!}E�j�C{�3�c��d�8vM�86868v�t�9%�FL��c:�8�
��fT�p[liE��K�aB�����C�k�%W􍠂Z`��J���W�TMl͐Di�i�i�i?.���i3���i�iC���Րi�HpP�%(�����ܮ��n3������}p�����׌��?T̶��l ��J�i�r�uȭ�bEU�z1ƭ.^О�O������ܺ�$�D~i&�:���c�pppp#�P�  7�A  7 7���Y��#������e2�x��Pxxx�v:
�͜�o#�{��Sx���Fu�����[�$o��e*�"n��V5p�`7� �ܴ�RnkI�M�%�A~�N<�����Ω�?��������|�` ���@ ���WԬ��;r�{FPnЙ� �)���宝��r3���܈��}t��xHW�����[���R�xf��N*�!@w���l�nMie�n�Het+�t:'ʆ�J;���G��kkkk���P�?�6Þ?�6�6���Y���X���g���
 �b m m ���(�6sJ
������uLm@{ͨ.��q�p@[�5&^J.U�;IД���vE�r1��)R&�n˫_��$˵eC������:�������C9�`�;�`�`ؐ��f5dء~�����]2D��������v:
~͜��_#�{�1S�ZP �׌��@ ``Kr�xI�ÄLE]k�A�%YnW�������el�Ju�`?4�������z      �      x������ � �      �   �   x�34�4202�50�52Q00�#�����\�?
�/.)H�LMQ��,.�/��L�,��p�24$�=� �(1%Es(P�%a�II
�E)�E(�=��@V��T,�6&������ԼtW�2!% �6ǔ�`5&dL� x�~      �   G   x�3�4202�50�52Q04�21�22��,.I���!��̜J.#�
�SS��*�	����+� *����� �D�      1      x������ � �      5      x������ � �      6      x������ � �      �      x�ܽM�5�v�7V>Ņ�q\|���َ�xb��A �0,	0�D�|@��S��Or���ZݛL�aـ/���5O���e�B��x�/��~��[>b�p�/���۟����������������������o��������������/?�����������������������������_�����?�_w�g��������������_����������_����[��?����?,����?�����_���-�����������?���?��r�����ǯ��������?��t�?S����/���!�O��.�����>�j�ނv߇^�������Ao������
���|z7��oA��C�
��mh�XA���7}PUh��}hw�������v��郪B{�|��mho�Ӿ�7}PU� ��}�`�ӡ�7}PU������l�c�o����I/����'��N�����I�,m������Ⱦ�MTZ)����'��"�����w��O�
�ٱ|_�z3E��)��~ӟTZ)���qrK����{����'U�NJ���eh0Sd�"��7�IU��"���8	f�,�Sd���}'I)�c��f�,�Sd���}��I)�����L��{����th�wR��X�z3E�)��ӡ��I)������L��{����t�Rd���o�c�b]���Vzl��D����ȟLY���#/,31f�5C���WIi������f���[�ȱ���Rb������6|Ec�v|e����t_��:�� ��!rj*,+�3��'��#���`����,�a�~�����W�����S���l�z��'SE�����اY:��팑K�3���������[����%e�1�5��/�'�*�Vɓ^&N�h5�0j`M���a�8���Vh�<�����`v�x�ar�i��*y?���y0x�ar�}��*�v]�}���'
q[�O�J�����:��#|hZ�=��x��?����G��k?~37��xTߓ��F �S=>����b'�LY=>��#��$@d��[^=>��������^�����'0ry����}b "����*�{,ߗcO$`䖊�*��d�	Y�r�
�z&���@Fn��B���O$@d!E�
�R�Jg��v}��^�_D���	��Ix/ÿ(0�Y��$�뛄{Q���}A��D�뛄���Р,���:3��&�C��Р,r�/J��s}��T5T�����;:�}�~�ց���H뾀���x4���p�m�$�-�����R4�=���m �4��s��8��4���#I����?�*�
�S�[4�G"���`h;�v�L�(�=C"����ݵ0�B��3�>�Y�?���p��<�5���}W�#�$8��"�a8���~�B˝��^˳�I0t{��k��L���&����^��2�h��7	����5��Z&�+�|�`�\Y�q�c9��G6�C�Ђ+�5��Z&�<��[`�fD������ňWPlFĈ��<�E�x���.~d�<�n�(2�����Z��@�%������:�{(2"4���y�d�f�<�n��M)2����<�?�*�Rd�yO?�yC��lS��1��g6�Ch�ޔ"sLK�3��1t{plJ�9������Z�ToJ�9������Z\YJ�9�����ZdJ�9������ZmJ�9�������=-w���|f�<�O�(2������]Y;PdDS��-�oZ4c�@�16	����ia��+E�l}��%�o�K�])2�x8��Z2��}�pZC|����3��ޮoǃ��Ӛ���fkX�l�D=���ܐiv�y��ڕ��C�w���Y��CkWJ�����w���Y�>yW��'�0��O�պ"�?���e�@�,��o�SEv`�w��������2})L9���!�'�ja�!G�L4�?�W"'q|%�|?Y��^-�r�s�ja�!��e��<�W �fp o`�(2��.�PUh��S�=G]d�*�N)�c�h[��.�PUh�����u���B+権+S�E�
�t����.�PUh��c0G]d���J�9�v���BU��;���{���BU��#Ҕs�E�
3_g���BU��"��.�Ph����.�PUh�Ȧ*���[�E�$S�E�
�1G]d���@�1�����,T(2"?G]d���J�y&X4G]d���J�y��y���BU��"�J���,TZ)2*?G]d�*�A)2*?G]d���J�yj|�u���B+EFY,�QY�*�Rd����QY�*�Rd����.�PUh�Ȏe�'v���BU��"c
����,T(�H��S�E�
Sg2E}`���@���9�U��@�1�9��,T(2Ƃ���oZ_D�ȸ��=�̾� ��Q)����{[�}�A���Rd���3���,��J�����ݞ�7d�ET�,0�����i'~�J�Ƌ��ɞ�7ݼ�rT�,0^\�L���1� ��rT�,0��L���1� �sR�,16�4/$a`���c��c�4/$�ƒRc�Qc�4/d�Œ�b��6���^UY�礔Xf2�4/d��HJ�e��w�������[fhT����ډ߷ҟ�џ��md�>�R��IaMҶ�e+)홙	a��md1!,'�<3e};K�F�r;+��=M�F�r;+��i�6��'��O�Az���,[�3ПD�n���,sv(P��w���,3Р���,mr@m�@���ӴmdY���#
�i�Ȳ�7=ƌ�m#�De��)���m#�D�
S�;K�F���+Pd���,mY��U)�����mc�cyU�lef�OӶ����yU�l���gi�X��s^�"[?ъ5K��'U�V�le&%MӶ��IIyU�le��Ӵm�2;�*E�2.kӴm��e-�J����κP�M)����Y�
�����U��,����m|RUh��~��u���@�E� ��m㓪BEF��MӶ�Jg�(2bR�4m����7�ȈIIӴm�bRRހ"K�==K��'U�V�l�X��Y�6>�
�����i��daW�l����Ҷ�� ®�F���Ҷ�ɖ�])��1���mc�fs�RdS~1M��&�/v��6�{x���Mv�J�m���4m��]ە"ۘ��Ӵmlb�pޕ"ۘ��i�66�=�'l�{z���M��W=�`c��Ӵml�=��i>0}�s�m�L���|d��h�8�*�U�ˌ���S���d��W-v,��s�m�L���|������ȟL��Î����@�6?fU�8�'~�_"_5���o�K���h�zGV��e�T��p�[�ܪ�p�st�]���JL����.�KJ� ���h7� +�Eu�>�� ]��y���R_���|"2��j��ә�2������� �G�~�e��խV����9�)�V�Juf&��Dd���rV��B���Z�[�T���f�,U���p,���\r2Ud�;7�����f���^W5i��ۜKN���t'��y�#��ҝ)x�
"�H����Z�m�'SEV�kg��&��vQ���
a��JLqI�L���^˿-Os2d5[�LTRLqI�L����e�~h�K�d��W��Z��Þ�:�*�U}��[��d��W�u,�UO�A��X���
����O`�!_�ױ̸�L$8�*�U��	��IL�N�
��dꤪ�@��YL�N���)�����IU��c\x&1�:�*4Pb��$&S'U�Z�ȳ�b2uRUh���YL�N�
���c�g1�:�*�Rd���Lb2uR��i=[0.��޽˵�}1Si���v+-��I�N�
���c�D��k�TZiQ�D�f��:�
��$�Z&~ޓ�k�TZiQ�D�f��:�*�Ң�關�^뤪�J�:&H6���IU��uL�l{���B-J��b�uRUh�E���:�*4PdLO�$�Z'U������b�uRUh�Ȉ��,�Z'U�V�e"f4���IU��"#bF��k�TZ)�����Qfr2Ud%M�G"�YD�e�'SEV�$0~bO����b�����Dd�Ö�Rb�.ORL���J�Ef����;�)n�$���}b�D���R�32�(OD    ?�({Q�Dn�'){�e5O�X&��>���t�U���b�@N�l~U$^˿�z�d��J}%�[~ba �e�-�{91��'BdS6��2�&���@�\���z��]Җ����Ld'��qF��l�V7[�!�����4>��'�^��Y~�Jw���1r��
�/��!zd�/>�Z.V����gBÝF�jn�ӳ8���UpG�Lxb�O#�L�zU�̘�)a'SE�
�H���oAm51�L��O"9�*����Z&�����N5-�X�<^ ���T�"^���s(퓩 �I�zV͡���{J͉8���J�d��W��Z&:p&�'U�V�+0�f�'U�V
,2����(��Ԍ����$�3���3�;9��̲sR͇�+�8��\���7�㉢SGGN��|U`iaL�q|�L oj2D��c�8�����\�D���q|%�����ꌝ��J�/vSs!����#��|U_�ꊝ�͜dO�\��k��9ќL����;Ǜ9�~�����:Ǜ9ɞ�MͅHTO�,o�${B75�X&�I��f>�
������Y�h��	��t�D����D�dO��C$�'t'�${B75!"Q=��8�$�����	�ŉ&ɞ�MM�H�r������VS"̟��,�����p,Gb����O����X���p�9^ϟLY)��k��^ϟLY�JHuf�q|m��V����f%�LYi��	�Nr|�2īf%�D3�$��.Zٷˬ�p<2)��~���Ea��	,��-cd�-g�<�����^���o�K��G�3H��_��3��夷�v�"�q|]�����8�.�,�-E0r�"�*E8�'__"/?�aϐ�T?���v���_��U}�����3�^SE���W����f�˟L���^ESs�����[�����!�1�0�AK�fƽ�����N�5���A��=��)o��p�\�X���Y�;�L�$(L��k�qA����2���H\�f������ƣo�����K&3���5yMN�?�/˄���XIP�X{��o��W]��3e�}������%�93'�]�ﴽ�yt�C4�s����A�a�af�L�%(ެo�:�����a�[��9F�p?��ŭ��P2f��	�JZ�j�9����?1Ob��$��o�q��z��۬X4�bQ���6Ӟ���+��p���q?���vL	"0�̙=S����8L�W����Y�`#ܸ~p�������d3�ܛ���=Gw:a`����˯=/>_��#��iw��u��®_l�H���� 8sv�ؕ����v�7z�����~�D��L'��o�x�=�Ck�K^�2Q�d7�����o�O�ʮnv�ݮG�0��ƾ�H���]�@�nF@��ݩ���.��g]
\a���ΰ���G�%{�4�g�(}��;���fK�U�E�?1�
��9�����=��#���x-l{��]>���"_ێe�艵|��m�Z�v,3S��^)=�aN��|-l{-�]ˇ�[�S�Vy���D�ȭy$^��^����'�adq|]��^�L�=�X���p�-^��^�sK�,��U}���R#7)���+���8��H���J�DDa
O�BU��K�]��"��B+F�[��S$�O\ڒRa�2a�0��H���J�%.bb0��M˜��X�,s��)TZi�DY昉1�1���eNRj,Q�9v��{z��ߴ��IJ�%�~�L��{���ߴ0`�@�%zv�M��4��CSd(�@��խ��1�O�
�Y�[s�s�g�J�e�[j�0`��RY����&	f �\?���̦��]�*r��L��?��T�W�|�[��]�*򦗉6��ۅ�"�`��%5C|�0����s�~�d��va��,��Ō�۷|�����&������oy��va��,Q�)�ۅ�B�Ed��߾U�
�X��� 9K�*�?��}~���^�R`�E��J���E'Fn�sS
�B~���Y)0
����Kd��(�'��/�����(:�DV
,3�'�N��t�����L��%4�_�,��)0z��
4󦚢��PUh�2�9�*
U�ޕ[��)�*
U�VJl���(�(TZi���ENQTQ�*�Rc+2����PUh��V�fh���BU��"[��<SU�
��ʄ�(�(T'����i�x�����>��{~��r(`u��([�����?W9�tW��B�$�)��E	��c�u��O����u�E��A�m�[[�IU�YiPj�'���}��@)�Ib���JnL��$1�M���R��$1�wd�=)�Ib���JyRȓ�|ߑ�5E!O�}�V����%���d'�Ș�W�	O"(�Ș/����هs	�t�Ș��H����i��龄F҄�����u�Tڃӛ��<�w��qvNo�+�;���=����@F?��ߡ�A�3���`�w�ȼzVr�v.�}#&�������i߷9C@�m��S�l��΄����cK��@&��"���so��V��pf\��f�m�Y�*9EEd�hPKA��`81�"�E
soK��V���bxC6�Ӓ{�i)h�\�i�L�c5����w��%?r5�$2��լ:a%F�|���oOP� R��,;����u >Δ>���'��q���Ȳ�/�A|��~d�ї�@$<Q�����(�J��_f�i�L��>�NȂ�"oo��јF�'�]�SE��r N����#�о氀e"���]��-�܏��XY�ك��х'"�]�r�����.�x]v� �'_ ٵ	�r�.{fv��/�����9�幥����"a��w�Kd����_�'�*�R_�^R^��Q�/
y�K�Y�����?��'SEV�+2����{��������:)��T����˾��0ra����5�<�^�o�*1_�w&[��K
 �b<��˲w���?쓩"o�e����a�Ly�.�_��A�rZ�ˑ*��c���M%�����`��^/��I}��"�L4{����m�ٞ���S4��`����=]�g��C�,m@�tU_�����/��T����̉��K
#�[�/
���ԗ�J}Q�O���B�J}Q�O���DV�B~�%�%�R_���/)��\��܊[�'�>��D8�xI�Y��I����+���xI�Uj��2Q���K
"������},��%��*�
�群0�8��˲[�d�/)�T�[��r诀/5F��'�`*�뢗�aG�?�SEv`�����[0Ud��~V`�v|�A/�����Ol�T�#X&z�xbc�ZX�z�#�@К�2�q�Ds-����
��/�T�7�L��i�������R�Ls-�.�(�4���N�}Sl���#͵ �'U�V*lc�#�4���M�lJ����#͵ �ޢ�k��s5���v�qQcCK�o�v���J����3M��f{�Y+�3��4���V*t�n>��B�����#������T�����<�g���,̇�?��#xff��wY2�}��D��,�*�˿'
(�*�˿'
(�*r�.�r��Q@�T�#X�;o��[�fO`��D%SE�z��"O�J�������Ly�D	�㣀��B+����㣀��NˢX�5cUU�V,P-쏏J�
�TX`*ԟ�T�0�k��Q@IU��c����I�
�3*���0IU���U�0IU��c���7�СAEF�e��o��s�����{��!�n��EFtx?s��nVԋ���|�	���,1t�v�od쓪B+E�� ���+�ĕUm��+���^�7m�7�EǱ�J�F�f��c$U�VZ42�3�l������VZ�s30Ӣ�olP��J��G\�fv��ot�B+-��`0Ӣ�ot0�����hd	��}������+-�.�`vo������4h�E#էa�EC��`l��Ң�2%6Ӣ�ot0�@�Z��3-�F��y�Ȉ@Y0Sd�ot0�@�����f�,��V�{@EF�/3E�Fck`8��"#�߃�"}����������Y��b���"KD;��"�}���T: EF��f�,��F1�    k	@�1df�,���VBv@+E���hW6�7:�Z��Yb"'v��}��N2r�"K��h��b�Yjc�h���y�Y�#K����V�,1�y�L�ž1��L�h���-f��b�Y�uUA)��4�$3E����Rk�9��"KL�$�)��7F�d�$*E���I2Sd�o�,��I|Wd�#n�N��U�"+�*��ˏWf5BV���8�j���z5S�+T�c���Z1�h����X���;���#�M;V	kĝ~�ݷs��d��,�n�m�1?�ڋ3�?����c�}��G�}y̿o�����o7���ݸ��#��-=���*�J޻���oﱄ�*A޹���+�H��;|̿sA�t�s�~̿sA��A޹ק�w��A޹��w����Թ���;oy��A޹���;�H���̿�F���#�R:7��i8��s'P��<#Gt�tn2��[{LF�9=A�߹ G� ��d��r��Ή��A��y�3g���΍2�߹ G�9�2�߹ G� ��2c��r����}3��i��4Ϙ�-w�"G�w�1��9�py�6��\�#��^��\�#G�wn����#w���wW��w�z�W���έ5�߹ G� ��_c��r����M6�߹ G� ��i��;ߐ�#*Z;�ۘ筬uC� ��sc��r���΍7�߹ G�9�7�߹ G� �܂��;G� �܇��;����݌c��_�h8��sG��w.Ɂ�c�;��X�h8��so��w.�w����:��h8��s�N��|�p��ݪc�����h8��L�%�8ܵSI��k���(��v*]�X�N�e�����J�����2��s���2��m�[Xu]�T|.�&7�0�'��{�O��m�}'Y�x�Vq.?e������2��\~������ef��2q�?�_r���]�V��������`�иX~� n�/<�/\)���i���x�~w�l�����u y�wPm� ���`��ȁn#�A>�_���\)����K�ۯ�?�*��n���zp�&o߹S�-3C"ܯ��S#W�-3�"ܯ�ɛruJ�e�����:��y�9�4\f<�ܯ�ɛzuJ�e*���~L�ԫS�X&��<�_���\i���	o����@r�ިNi�̘�=�_���h8�+�u0��΁��ĸ����`��J�@�1h��ׁ��#�y��.����`��J�@��������ꁆ#���ׁ�-[�<�p��+���:���R=�p��+���:���R=�p���~n�&o����3 ��;O�V���>�_��[h8b��u0yS�h8b��u0yS�Ai����>�_��2���[����u0y����ǯ��S�	��n�����o��ջ���W�ueb��S�;�n��������)Ar'�\i�c��m��>%L�n��ʌ%}p�&ooԠ��JM�xn�&���vM12��T��ʽ�eOd����x+ܗa�˄��4ս�r;�|_�MS�[�*�����T����2u�����U���gҦ��-`�;�����i�{X��`���=Muo�ܫ^f*=��-h�(�DT��S�[�*9�l�� ������T[�X��'��-h�\�c�W��c�v�%�ܨI�U��J��۱L�I��-h�\�7j��Dս��+�Fu�NT�[�*�Rp�t׉�{Z%W.}��n��ނVɕ�;�	�y�{Z%W��p;QuoA+�h8��|��ނVɁ�c����-h�o�Ƶ�F%z���׮���9P�L��<u����JD'�k.h��W��q���VɁz%�'�k.h��W��q���VɁze��k.h��W��q���VɁz%z�'�k.h�|U��5�����Ur�^3������Ur��2������Ur��2������Ur���#�C�k.h�\i�c�����Ur�ᨎ��Z%W�긞����Ur��2������Ur��2S�7Q}oA+��pD��D����GD '��-h�h8"��9���X6��~�H.�p�pD���`��bـ�#� <� ���4Q��9���X6��J��!��p��|�L�4�4Q	��9��i�]i����hAA��J���5\2�pi@���+w,��p�Låq�O�J�4��8&3���V�|�+�2���Låq�UV�W��G"�.���\���W�s�Oԑx�U�~{-�+��1��r_��k�Wv$�`����^˿�#����/W�v,�
u$�`����^˿�#���W��Z���'X�j�����{����r_۱L䒦�H<�*�Rl��7SG�VɁf#�{��H<�*9Pm�{�T�'Z%��pИ�#�D��@�Y��:O�B�v#f�MՑx�Ur�ވ9�Su$�h��7��r�����+���:O�J�45�v��ķi��))O��:O�J�4\d�NՑx�Ur��(O��:�t��Ni�Hu��ԑx�Ur��(_����t��^i�Hu��ԗw�Ur��e�V��/�D��J���w>S_މVɁ�#ꁦ��K��{��~k_މVɁ���}y'Z%��C0S_މVɁ�c��ԗw�Ur��(O�����D�^i�D�!��/�D+�Ai��TBM՗w�Ur��(O�����D�Ai�Du$�ԗw�Ur��Ց8S_މVɕ�K�$����N�J�4\��D��L}y'Z%W.1�ש��N�J�4�6U_^��h^M�H�'�T}yIz�y5�L�h�ԗw�r5��L�h�ԗw�Ur��YS��h�h�Ht�ԗw�Ur����T}y'Z%���N՗w�Ur��ܟ��Zf|���*8V��u9S�v+��M�U�U/}�st0�ʽ]����9:�ܛ�$�S��5�n�u����Z~9���a���9z7X��7�����wC�Un������>�MV�*��.f�g�o��˔O�co����%�˹��F�n<u��&;7R�,���ՙ����Y/3�'����`�{�.;F�<v���v�U���L�r?v��[%wگˑ�Ox���ΣpO�y�.s�&����J�U�˄>��w��>�W������CnQٙ�z�S�Ӽ�X��5OyrO�-`�[��+<�y�����^۩�x����J��L�h��|������N��Nt��o��U���+ޡ��+��U�jz�D�� �w����W�>��<�U��W��Z&*^��-'X�교(�yt�	V��z-�L�����-'X�~�k�x�1U>�p�ʝ��/�cn�}�?�~�y��&;kڐ��2{��]���I��?��W����q��.���O���g�X��o?��?��������+�m��_���<\�K����f����r�+�W��=�r)`�;\�����'X�`�d����V��^&|�Ql�r�+��$<��ꩿ��~�ʽ^�)��i~��ro��H�o}��pǷsm�˄�cu*�.����k�թ���k���D�4:��Un���N�itj��,����-�*w��D�d�mV��^&<nfq�h�\)�D�rN�-�*��l��,.���+Ֆ���,.���+ݖo�Y\���aQ�-Q�&q�h��]���$"s���&-`��_����ߤ�r�L����&-`�;�e�`�7i��I/��4o�V�3X��F��MZ�*����.�iޤ�ro`�~�e�7i�ܻ^&�]�y�����Lx|L�&-h�\)���~围�Ur��VF�M�&-h�\�6j2�Do҂Vɕn[�n�yޤ��+�2��ޤ��+��2u/�L~h�\���q�e�@��J���q�@��J�mT��$��Z!�J�mL�t��O��+����O��+�Qa&��$�*��p���1|����#�*w�.SU0sDZX�N`�����ʝ��o��`�{˿��G�U�M/��V�#�*���	��9"��p�y u���=G�U�Un�����9"��r{����Nih�\)6j��,�V�VɁf#&\�ih�\�6��j�H�@��J�%�c�H�@��J�Q^�DZZ!��.����7��k�]j��~��c5���.���ݾ�J�S�>տ$W�3������ߺ��)��    �ǿ�V�����搾$W�8E���ӗ��e���ن��o�J��Y�������y�ܭJ?�[��Ox�{�+����ޮ$�D|Ɏ�(Į?7�%9�ə]7��޼*�Kv�R!�S��9�/�ѽv�����/��b'I�[��[n!!��+���$G�b��=W�y�v��]n��W���̮�m��=G� �,��n��T,�n�B?���'|Fz��ś���v�c�}��؇��i9���~�c����z��
��c�a�?�5�)~A��
��O/�$���E͑c`u��枛?�귾��p�f�y�j��k}+:�	�`�i}o�;b'<̤l�dk�V\9ѹ��\��uB�v���'��[�o��с�Q#e��cv��HEݽ�3}�v���q�Ǟ����@�i�N��!*�9�ETK@8{�}ꃾ��c����*v���R��[���� r/�.�����5���X�s�V��K�F�	�¾9�|σٖ���V�їN����C��: �~�� ���ݖ�F)����T��I�������`�x�&�s.�9��u��h�`�E�r�R��׺�	���\}�����_�Ѯ0�k�I�� �6��֯v�Ƶk���+��N�]�e�ZY �*;8�	�l����r�<���f�nۆ��$;�u�z��׷!']�s�3в�j�Y�v� r�h��7���k?��+����k;�A�MӠ�ѡ�w���>�_TM^��y��]I��5�$�j����cvG��
�UT�V����Ֆg]Qu01���Sc�WEv�g���Ccz?9�&���LcS-�<Pwt�1�u��\S-�r��/3�u��z��u�Ge�g�ã3�٨�ݛ5��f���e���4�nk�<Hr3%�7�ɳ��8�����ș�+y���og��p�=�,�>�ʬ�L#�e��^NgYw�R��m�=�!yF�m#^�vA�!�)I�~�Lvٮ66u}��+�.��y;9����eE�x��6I|dY=ʻ��������X�թ���1�����e����l�T�bПh�|�Lv����dE�e]r�3.9�$9����ݮ�dPI�����8"�h&g��=(ǈN��7�n���C�e�QU��FC�̮1h�a<ؕ~?���k�.�eW���C_�I^m ��!r�n���b�P^�x��%��̃�cE�U��f�f��-צ��P�&�T۠L��7�o� �ɮ26�ܒ� �Nd]|6<⇜�2�r�_r\tj��N-�;Y��NmE%�܋{_/�{Y���z�=25c]�
`?��/����z���T	��sJ`�~�ɮ��o�8�='���R�qL�U�]~��7�͆�.��N�����1�"�j
����<$>%�.�:���2�qL楝s圈 f۾ɱʞ��D<�,R1��I�cQo��o=�E%È�������NEd���%�}�����ݨ��n�u�xs�xl^��������qg�]ߙ���wD��>�u�p�=�/��ݳO����I��U��X&*%�Z�\�/WصS�f��=\݈�kh�/�"v�?֮Xҍ��-���Me��}rvi�7"-�J��:Ɖ�.d��,DO�'�eG����ˍ�L�+��Ϻ�\3��h��c��Eo#�5/�I\�Pg#��tu6���\�Ӌ���3��s�c2b����_�!o��h�4�i�%����Y7���3������7ǖP����5�4�=vE�D�u��1�i�ʺݿ�욝�:	oATN��v&s~��\�XQ �n�+���j�scG~c�_.�ٶocv�e�7��n����%2O�g�q��-���y�^ ��2Ov��e@|� Ģ�^ ;S�e@e�{�	�_�}��A�A9�{�V*�b���y�Qgݱ|�R��M�t}'u
�®�s�ܓ]�m�C�[�Iw8���0.��� �p5��:&�f&m�j�o��ݴ?�{������wR���h��D�]ͨQ3Z,�`G9G�}�˷�c�}�s�,�g|J�N?����V�T����O2�R�Ň�g��ݘG�ي2ŌV����|�ȴ"v����;�iPo+��3ǮS�:gQ���������P��:A>����E��l�I�;�ٴ(���3�}�iH]��g�����g�c��I�t�)w_���b�j.gq���؋���#�.�*w�.���Ȼ���{~��r������ݺ�oE�{�i���P����������n�$�c��+�˸r�m��QE4������cj*D�%ns� �������f
r-@��L�ݾ�q����e��e�	`�褻�If�|3{\��ZI�9�����ņ<�9Q7����1]ܭn.��}�E�}2s]��f�z�f�K;h*m��]ў3��v��>d
����}�TŠ���}�or;�7�PB��m��]�ȯ��A��t�!�$ҫ9'��n�G����tp�ήZ���LaE�F┷K����u�/�<#�lh�3�9yG�ۄ��	��}�񢉼�o�]�e|'/�u&�>��bG��L'�YbݏϬ�}�f�ڱ��)�Ѿ3��N�!�u��ĬN���	�Ȭ��mD�L�%&��F��T�ɹ<D�ɪTM��!fqTEu"����M�#=f��u'X�=%�K|�����9ǜ��&Q/v�S�{M�	Vs�h�	���0�qLfZ���9�0�r�4{�v�&9�*�����ܬg���� +�t4Ǎp���X����g���1 ��{�8�p�g���&����SqX;�e����A��}D��b�d�j�[A�^���q��+Q/�ֱQ�6ӱo������w�#�p�kݮ��Ȯ�u�G�����E�݈����hߙ�}�|[�ɍ�c_{͑�v�{����[�����KT�� ]¿�<K]8�Ԋ�nL7�]��oeQ���L�$Z�x=���}���B�JQG'���s�C<�e�3�Y�%A"�����[6˹�1��-� }5�@��O�{����r��J�4����X�vz��^hv���=��;7K7��g!*D��D�W���7Ž},��m�7F!��_;�_�L���[�eU�����6k���`��ک�����n����fF�d��%��N���}�f&ֻjuV�U���t��R������͙`U9Ս�7ص:��th�.S��BM�&�*�R����=�����E�V��-�Q&���_��M)��q^�ŉC�Uru�oT���*��.�*�z�nLŷ� ھ�gZ%W��Fy�]�k�U�Ur�׉��,�+��%�6����Q7�V�wp�{"
c��3 ���V����%�=��D�� W\�=��D�YDԿƐ����x���=.h�*ӻ7ˬaݻ�!��K��}Ox�&�w�na������ۤ�� f:;f���;x�0�j������;�a*�'�L��yQ)&�fW4 ��y��y���Of��4`Z����;x�1�Yf,���yK1ӥ��ܠ.��Y�At���hw��ؚ�R�#p�$ܐ�f�lۆ�e&�nS��c!��$N����̱��|vZ��'�"G칝M���Z���12�f�#�ξ;��n&��m�+
��!{�P����}7���1�y��uq1lv��1΁����c殚�X�7�殢�E���n�GĦ޻��[&�n7o���A�{����͏p�x��Z��NTD�}�c�=7v4k�a�K���֥��pQ��#:�#g�fO��g�~�^�ʞk?drΰ�l�^�s���kw��p~�3�:uv�ҩu�+��Zw�w:6�c�Eߢ�Ȕ_�]�q�w���D�����]0����#�L��L��%Z�:VQ�.ӱj��Ի(:V�}-?�,䘉�q�9�f�|�Z3��UcB>��$S�4������ҥ�D�4M�,D��� D>s�u�V_/�Rr����^Ќ�sUn��gY���-`��&����M>I���	�USv&3#|��[��sf��,sԑS(r&&1��@L�G���Ĉ�a�:���S_�v�	�Z?j��ڽS�!Ucr%��FLv0;��N� S(#�#^�]Tj������j��	�f	�u�빘���M�J��m    3sV̡U��J��}̾��mG�$DM�b��q�5D�n��Z�o�پ����T�1S�B_����QM�j�s�*d�C�����]ME�Z�W�K��E��N��+�ˆr�L~�.�l�{��?�_O1!�L�1��'?�+�E�3ʶqI;A��*ZW�w�q"^��Lp��TUD���}��\�Rr���5�a#Đk�B$4���k�.�w��@���['��-�����Ůrn�רEZ�/�P5v�n��˽%����A�Met}�2
�¾�"�8Ou����=#��H�2��C�1u�u�"]ðg����O���Kv0y�p)q�n�sתxW�=�w�d���m̾7WM4i�ȸ;�VG׷�Q�Uv���ng)�w;���y"Ze'��=/|ZЌf2�b��Z���_��-��D6��F����p���݉k����5����Mf��.Y/��4�
X�z�q5�������St]�^D�Y����'X�ޮ�+S=���V�W�g!*��wQ�*���,D�4s
X�v��c2��L�*`�[��SN��̳)`S������ ����}�A� �{�VM��U��IdV�.���G�U�S&&ژm�:d�j�.qE���6��6���e��ta&�n�o��N�J�R�~LNٷl��(�l�,U�(�v�Ȧ�f��/x�KG{NԆ�e����2�4f��,>k��G�U%���Gܠ��Ǝ��Ծ�E��D%;��2�qN��<'W�3�w"�po��=o�!~$��ٴ�}g�(�*H�g
QE�4��κ8�k��NU<���J��J�i��@%A@�LFَ��.ʦ'���߇��}u��Ct��u�H�	V��qa��&ʨ�`���a;���}���	V���c��Q�E��g�N��}�$���e���	V������'��2�'X�VL�_}���	V�����BT�L�Y<����<pf �α�z6�ꯙ�虹.eTO�����y�L2][�՜*�29U��{�ِ_$�;3�`v^о�4Ȫ���͊}�~I��Q�p�ٗ��q	�hϙuvU#c�Z�r�Qg�}v�O}З.z�Q�����v�}L^Qd�Q����6��������g\�؛{��tp�S�t���ܙP���簘]��?5�;u0Q�d;o���Z�� TF2�(�ym��6�KG�;�g�fVʥ�۝ȥ{;�)?��t�N�1��u}��"7��g	�rkq�GS�;ʩ]{v�|ܘY>->�v�Se���}�,�ƞ�������]_hW�=�P&���K���	"�މ8�]��S#):�#��f�������eԕ��:�3��;�NPt��kg[��˖����hSz���r�0b�I���'����m�������S��/v�N��Y'�=+�\�����^!��yb������7��!�}�|�_흧RZOYG�b�|�v߹è���c�v?��]�������,�������d��v�]�1�f��*Oh���c:e�E�	Oh3�y�ȼ#�g$\)���x����s"�d�l	�:9�70�>1��v�1��e4e��h�]'g�h4��0Y;v�^����
e���~�c�Mˮ6����ڱ���]m����ě)y7F��H<�w&oW*<��PD�=�w�����/2bg��2�c�Ho`��g���*,�N,DY��x۽_�TTIo`�q%؝]�ƍ9�[���Ĝ���ǒ>�i;����r���,���V	���=GG'�N?➣sqg�Lħ���`�{����{����{����st�
���q��Ɋ�ݏ�g���y��U��e[�1��[E�Ef�]��:$
)}rQ��a���2����Q>�v��mL�v�����r��nR�3�JfWQ�龚���|�2��U4}����*h�w6�$Ujw_�tp��>��S�]�uP7o�p�P^�qδc�c؅k(�her�v��qL{�����Sy6���1�V���w��n��!N��=��&�`�s։�{ qwf��$���oJE�{�Y8L��&�_��Oݫ�����v�Fpg��k��p�����7�)˾�eW��� ���Yb�u�h�\α����6�F־}����,�>�-�V�����X����$�ˢ���܏U��^h�\�a�eƁj'"W�e�\]&\��jGB��W�Ѿv�s*X8Ⱦ�+'������u�u��p�=���p���}�u��p�=���X&~�v��nD/�'\a��{wDl2�Ղ�1�^c��40��f۞�x������s���ħd���%����s��н�^�U�T�lkZ���q��T�c&։�#�AG�/}3�Mx�����L̍�y���y�r�˹�ձ�QM%e5��ܘ�ᨙз�L����4��9jf�gf�D���	���oL��ݛݏq�l��H�QN�vg]s�	v���DV�޶0�=X�V����®� ��}�����۷cOcj+��,��`��j+@��Gm��,@��L���1��gz�Q�vw��1�Y���,ӻn��c*�e�:�ޙ�m��}�V:��qе��S3����m���y���S�UQ;h�k�{+`�;�e�a��/���fV�#X&�s�"��kJ
X�^�gp�N���Y�����*��o���unԎ1>���>�c<��[򆦴��΋%v��p�}G�L��ݾ�ʹ�*وb��s���u����W��\�$��(ˌ��	r�M���g3j����*ȑc��h��#}x73��c��D�6��G��l6��A�xpԽOL%6�����(��T����r��$(�FT�L�	��I�c�۷��`�1�&ፎ�7�,��w�;ӻo�;f����ASJ�Y�]METS!�Ӣ�2SO2KM8�'AuDL=�]]�3�\�T�}g�I���0f�`G�L=��o��7TO�ؙz��|��$�7O�T��P�1��b2/�wʫ�n��1��b �/3uv�>��.����Nx���m��.<�Ѭ#j��7f��`O���˸���o�4[D9("�hW+�������*�δl��8����9��m������k����O����m%s�v�}��t�u�h�	��i���g��r�73�m�;���EQy�O�n2���r����]\~̄'���Y6��Nx��p�Ѯ3N�vg����iA}�D6�,\3�G�ec�C�<�ec l�`G٘���.	�g��g\��:\�!'��D��a��Z�Ls�Y8�����Ǚ	e�PΝ��M�̄:�QT�a7ӳ�?5�}EY8&c�yc�LZ6fGQyf:�]t6��ʋNG��a�<���yLT^���<��i��yLT^ty�}g�1v}�(��w&c��9�'�1���p�Ӵcܩd�+��3�v3�Ƽ�d��{6����8nN��(`�;z�Lt<N��[�*����a�8U�h|��,n�f/�Ν_�rG�|??ǴZV�X��O��[�*w�DG�wo��V3��u:�l����_^Q~��b��.��Li}��cgr�v}�q���eE�~L��.�4�?���z����!�H�aF��D���S1(���Ó� c����3�+�`����hư�n�E�v�sn�{tc�(��d����0��K�:���b���f��^GTY@�:�e���3:���"���2ʵ1]�vy��ӮP~�:�c����;�uy��^��Ӯ�#]��vg�<��~�I':Ѿ3]�vn�aL]AcGs`���}c�y�������p��@��<;��iǞ�ԋ�.O��
���yL~��8�ce:\��I�1o��ՋRuv5�c�d]�w����{S.ؑkUW`��w�)��@�$D���-�ǼeZ�kFo��׮�d�[&���{��k��#t��)�?��	V�W���X��~�=S]�;�����g�z�N�~�X�����r��!�{�:�Q�?��j�h�gݬh:1��kw��w�E�L?��z�e�Y~=����.�&<7��UU�cz�Z�ͣ.f&�h��5�&'��}g����nL�W�;�w*�w2�ُj��hBqhfJ�]<r8{FvfJ�]LnP?�ȹ���ɹ��t�1U%-:�܋]    ީoŨνd��A�t��{��UP�;�u�'6;��i�g��ġ[O'�����vՃ˘���C���Lڮj��q����x�L}0�q*�4���A�ݚT���v�cC"�b�U����⭸{��+`�;�H4s�����z������1U�v�z�S]�Ur�ua*h�D\W'�*9�/Ro6�'ۈ�-��d��Y�����VO8�s"��ax��grA��@����L����K������.<�{.sA��@�$�>72}�q��Ӯo��O��3{�u��`'�.'{�pT���W��_��a2��X������@��Ĉs=5��U}��+&�������������ђ��+��?���xP��V�7�B�L�ݮ��ow�@�{�4��af�����~��N���ض���os/��Y�͏?�Cc�����D�{�󅈳ە����D��|[��Q92�	wqZW�6e ��]Zi@E�'Z%WJ�ss���|@�����uUQ	�x�M�1V�*��Jx�o��fk@v���}A���%�;�T��=����m�dD���$�����%3���,ko��v"�`7z���e�V�<,�s�>�f���;2q�S��@���}�;����9k��ݵ�����ʾ���/�l��s�7KA+�	�Yѩ9Mo��+��l�LJo7����ѧ�R�+b�u�f'|r·���9�L���}+_Z!�շ�س]CS�~&�v��ũ���ot�p������if���K��3qY����_��[}C'<��'�~�A��/�3�n8߀s���}A��Dd*�%��9�-B�;}'�fB��t:��3R4Du�Y����@�*��#�8�{�T������,:���*���ћ���7���!Q��b4�ұ�<3���၎%4��s@w}Б�WZ.0��y<	\a*���|�mc�]��^��ӵK����>�
{�y��.���ܮ��+ѷ�<��s����(^AxQ�%݈��'\eW��d�krI��������Iv�i@���oJ�����%�D������[��=w�z�����w�������*VC����G�[����ΰ�yp�j%����N��=�݈��;�ʳ��v�f�k;����;f����H�0�v�f�]!�����a�{��uNE�H�1���u��k�8r|Jb��Ov�}Ik��u��?b�!-�3K��@+���x�x�����p�y$�|��#]�tW�w����-��{�o��h����E3!�x�������D�l�k�KC<}���h/����A�|C��Z�h7�b�k����1�_<Q+�W��\\aGӫ�If�\2�ҋ:2���t2��X�15E��D�_�z���,=��Z��=D�_��T�?5�h�P?3�Ď}Pu��G��+�]�>��]Ԙ�8U'>ˤyPc�;�RbhG�ݏ�����#j䧙5�j��P>������-C�]��$��c�k�D��fE}��2�v1�����	w�i��Zc��|��"��kߘ�-B�<S_c�L��ZT}ʹ3�5v�|�׻��9�Ѿ3��v����;ʹ3�vw\s�5��;1�n|��;�P�Uv�s'����n����if���|��+�s�~'22�����p5-'����;S�D^�o�#̹������%����?c���^r�"#aw�{p�s�fw �DL��N��N7�����w�/�~�ܓ��F=����9��~G�g!�j�]<:�ܺ�(���9�߰ڝ���������~�O���B�P�ͦ�`6��=�f �����}vF\8qY�����
.3����:g}����ߌ�jw�7���k��k��H�=f�>��}b�-�1���xڽ�=x��k������_�;�;�����Z����z���OI�sx�X��	V��>g|IV;}����?����{:��$�\3b�m��
�S/bg*聫��N�ڹv���3 ���d��5���z�>"�b���A_������}}����s��K�/A��\�kW��Zfޡ]��-������{-3upv��]�����]�Zf&<ؽK@�������z���=B����zУj�};��A\���fw���N���9Q���r=��5��]��o��&j`:��[�Z��G&����u#j{En0;�؉�ͮ�ӏ��=K١O�g��v�~�_�ڵt��A����̓��gu����q:&0�]�"�� t+��Lz���:��Svp�3���s�scn�t��L��f_���?�`��Ǚ��������vp�g����g{߼�	V��n��{|��0{���o���!�fg������ޥ;��2׻]|u�O?��n�7Q�ҹ�x�E���/D�����/{�<�	V��~{���k{�����;13t���Z�c�}��<Ą��<��1��7Щ��-v:��2�� ޡ@����#�7
�q�G��H��{\�գ��p_��Y�j���o��sj料> �h����t35��|=��{o� ��s�,�r�S����5�1�N7�y�`}����cČ����1�=�۹�@���W�.���[Z�jt@������T�=���U��71:8���u�;ԉ��9�B�G�f��ϓ�*W��N��t�1e|��^��F'ju��������F�Q���vq�sEI��@�33���Fw�c�iU�bl���.��:�؜�|���n�U]瘋=�+�z,w��Ӫ�s����$k��?-���y?�� ��;X&f-��:1�oV�e��[�v�F�����]o�������������"���]O���S&�*w�!wW#��[r'�L�r����~=e�r�rw�g�}�]<�n��j{:�u	v4ۛ�����A�C߸�W��gjn�f����m^�=D��2��%�Us�=׼�I�^�c�2Q�d��{�}BUfu�Q�v�R��wfuQ̷n�;�����y��c�f��n9PU�U��b�u[�a�cxgV1��,��9���T|�b�]���9��άb�2�lZ�Y�Ī�@�1�vR�s\�i1��pB��ZP#5FP�ɱ~�mD��Am���Qx�F����I�~�]�U��&c� f�ݲ���2���.h����H�Ԇ��ݿ�F�2#"'fҬ_^W`Uj�͈^���nY]D��Am���=N&��6#��e�#e�h�Ht��5=v����@�1�v�ݣe�h3�ڮ�{�LRmFͩ0���3��6c�M�ׂh3��Њ��wݨ�f�a�c��ZPmF��Y�u�7��@�1]P��!ݿk�+��Q9k�:$�A��K��q�K��k��3]o	�R�ڮ)�{�PR#]JP۵�t�Jj�K��i����1�6W*&�K	j����1CI�t)Am��=f(��.%���A��uF���r�k�3�������L���1CI�t)Am&�b����Fڌ�6�f�{�PR#mFT��i��?f��2�f�]�]����Fڌ�6�f`~��w-��6#�ʹY�3�H�ݯ��f�,�������Am��b��a�^�6#�ʹY�3�H�ݧNf�,��
j���W"%3m���[%Ҋ�Am��R����Fڌ�6�f��LP#mFP�i��?n&��6�_��̴Y�7k�H+�f��6K��f�i3��L���q3A��Am��R��Y�ސ6�_��̴Y�7k�H�f����6���f�i3��L���q�B��C3��9Av>"`�H��k1+�ef6�]y%�Է�<��sb�����}?=��%˙��j�껎���{.����e9j�]����N�?��r��_�Ĭ$���y�}?�*�u�k����շ��O�B�/����U�w��:�5�t�t��}�+'�:��a�{�����w[���\U0y����u�a���'����r�tۮS}{�{��.���eb�c�	J=�KL=����y-߿�톤�i=~��^h���n�Ҁ����3���e�͸�D������]'^읧�u�ŷ{��[g���^�n����)/$�e�i�v�tywP�m�uX�Ӭ_���6�]s�ݑ=�=4v�k���    ���Ƽ���|��{.��5ή�́
���t͎�:�ݮD�w\c�N;�;˖L���櫶y�.ˁ�JZyÅ������?�:���~�n�'X��7�~���Ѓ�}�*��A0�'�~�>�!�����(b�X6��s���:],��{�"},\$�nʖ.d�:���5a̎�����q=A�q�/�g����;�Q~����"s`F��m~�1�^q&�<ї��c��X�\�����o��h��;�Q3v�wt���3W=�v�ke�̆�FC^."Ϭ�!�<s�n��yf�b±̮<҃��o�E�́�oFӘ���KݸZ�i���N䘽�|����-hY����Gc�F�	==r/5��;��1of��F��?ȸ�;=����5nv&�CrN"ר<�k�K�ʬ�L#��3�6�H����F�Nd���]�%ӈؙL�;��ui����n�y n�=�."ˊ*�L��i���]3�o���Ⱥ8�b7���e]�|��2�e�X�2D���A�\��e�� &��ȶU5�V�l�U�(?#�Y��f���~��A,v���w��=���x"V��Q�g����놺��r��e�"��P\��
��s�\�}���덊���c�t��{Ty7�������^�hV���{�8�A�վ�ɹ��[���ԫ^&^�v-�¨�@`����Fc{��*c����˨"�8�;� �q��;�sw�aɔy��W�;�1L��N�ʴ5�PG'19Ůhʃ���ؖs����>{W��1x�mC�N�+}��(X�����ӆz��J��N��C��"봠_<QIb�N�����5:�a&Ny�����':�o�p,��<�1�'�oD��T����6���yB��L3eT�g_�9O�:�e ��sv��2�Ąf;i��h_Ϻ�9���<M5Q�=�Q���<M��u�<�}g���*�!������1���#��ޯ��x�]��Ͽ _�&�.nf���k�"���ϲn��^���-Q}s������{��琲a:��z��}���L^��,��7Qmť��]������w��5��X�z�������F���oJpg: �n��d����}������gXk��A���}����nsKV��`�~l��
^���u�����3۷lW����_��QN��[��>/��Q��eԯ��-O�[�}��[&��vR}HNt�n����5ٍ��`6l�j���Q��P�]'���u��fؤ��\�+��>_05�䀼r�J���zdE�c$���#�c��#8ʥ�'�:�Ǟ?pԵ{�>�f�yL��G{NTɭvw�:�Nk~�!��	���6�	]��"�H�!��SԻ*�v�/�r��Y�-�'P����� �f�T���o7ر�A�g��2U3f�0�[�,����Y����1g]��д"����1�}|�݁�����z>����Z�!w����e;�<���Q�þ����1��ƞ���z��z�xS�^uT�D�M��T��$�&:���C�[�rb����~�����e��ҙ}3Q�5�W�B�N���3�ج���y?�^�\�p�z���ww�>�*w�ˁ�2��;�i��X��66�:դ�K���v���)Vv�[g��v�u�_þ�Q,��"��w7&��͊nuB�x;�-?����C�r�������(VA���}�c:�De�b%<�}��{OCb��u�3^v�{��yvTa@��͎�1*�mF�<�U�u�O��ks*X�7����n�Ř�b�4��G���*�!S��e�!ػց���F��o�K������]
<�։	�vs��F�����ɷ���y4��\3r)`&���!]�b��nD�5��&㐻��[�G�L��.縎�>���Q�$��u��j�:�t��������zZa��E��X�.�4ă�e_���Ś>���pfwz���U�������	V��������fO����O�ʝ��%�Wp��3�;�ƽ�?�}��:����יï�_PC��k\bݯs^��_��U.��9O�W��2�VW9ٚVU�˫��n���?���WE5��W~��^���L�p����wv�E7f�p��.(�DT�����^�?{��=TF�S<��d�K=�v{�X��9&��nܮ�v{�]Ef��.�v�ܘ�tG���/s�F�A}�b�,"'4�٦�c���XЬ����cBe'bg�p�]nn�4�IH�������P���/ٹ!���"�K+��cz��ݏ�a���o�`��u�ް_�#�{�����>�yH�q��<��i��cr�~dGg�zo�ONC|���C5�lB�}3ѧ��F4���C�˥�Ѵr�4��)���|��=�a�������uEݻ�g��4���o?��r�ϗ��C��1��<4]�|
��H�P�y�
���Q�Z�S5��a���\W����ݘ^��rO����ݍ�Hۙ���?�*���_�{!�{϶���+�T�7۽;��K�����v��uup�{�ލ�muv��n���p�A�Vʙ�.:f��x�,��\(��&���#�`�>UE��j+�׺]�yL�O}��Q��U���`�.�RrW���ig1��a���A�-@�S���C}���b�U5����Q�Cy����Կ��M�(h���	%g��׽����=5�D=ɽR�{��!����9x��uog�5�ik��u��D4��t���PA�{: �Vv�u���*��� P1
;�:�lo�mq)��b���V���3���#��揻-@�u��6�wsU��s�}nh�6��-���v�~Į\�{�XA���>g�ϝ��ܷ�R#Ql8�aį=��܁���Mv�+Cz�Zw��n��ߌ��[�v�d���ܮ(�{MhA���>������Ґ8\�j������FE񝃘L$\(��=�D�bs�V��Ȝ���2?`bٻ#rD��T�P܀��^v<x����<�|��aM�zpʥ�QH;K�����r��O�Z�*9x�D�3���ҽˣ���w&����� �]f=�H%�6��݂Vɕ��o�hv���]�Km�T�
X����M����Q3͢qH��MlA��L����}w���V�D'�������'jA��J��;7S2�'P�J�2���4��qH�)�7�q�t���,2��YR{��bٙ:�d�bI�2����<P��kb4S�q@�a��[Pg�μ�����'�J�t��|?*��	���E��R�;�%���k�gم��ԭ�3n����J�ᬕ̔L�م���}�Szf�y�gم������^Kf��4 ۰��-�����Mfg{��e�og����$�>���Ur�>'�~���<�L��7GT�N4���Urp����>�^��[��_��Q�+��ǣ&�"��u�.�j�����Ė��Nd�63�mH�]d�"�q�/����+nA+�	�r��{m5;��!����kD��ʉl��r軨��"�Ή
����Z=�v�����L��C�{lQ���D��DuZ=���fg�:��{D��
��^J=n��^K�;'�!�v��8��{-�7:�ag�����Urp�������>_�d�������ô�E'�!���)���ɳ�E'�!&�ɓ�n���l3ݾ�NDq������z]�D�C;�38ۉN;����Y��9P��W�a�=o��4ѱ7�䖂V��V#��6�[ms�[(����*��S\A���>'��6��|�m�[�R���앺�@��-����q�3��X�N�5�9������V�q�/]{�m�hD}�f7NwHTBԷ� *A��f�؆D%Ğ�@���w�n�K߇D%Rh߸��7��m�q�d�߸��yLly���od�PW*ѡ8O�^A�_9P�D/�n�[߇ġj/��/.B���� �1n�s8^����;`uǁ^O��w3�����B����������fo�]�ь�[�[Wu$�Wv���>�Z@������_�~���}���"�h�l��'A�_.v35���[;^��_�0�?�}�����N�z���C�u���#�F3xV��k^��G�{�Jm}��hu����u]oq���5    u��ϵ�w��V��j�T�z���Э��بX~��miX���p�sv�2��i��Q���,�In�W�w;���8�)t��(���9�}�(~���oP���~s��^b�Q;�LL^�fi-7�?Pik��6Q���k����GZ\�7�wv����d��5~p���vv��h}���<JM���A��6�9����8ˉ$g��逓��b�ۯ("���#K�����7�ňܿ3j�a�-����9pwo���9��k|��v�9�Q�<�3�����[�;�Z�̘�7���~w�6ԼX��D��7���Ugb/j��N�%s��L���|4�|$������N�A�Įw��u ���\	�Q�9�ԁ]����z�c��ŞѦ�A�*��k=�k�ȁ���tȐ	O��Z�r,���[vы�]k�^&�5��!S&��6�#$�J;G#:|���t�y���s@�3^�?m�:��2��[�q�7U�]k~^?��D\;�ub��7�\�ׁ]�So���G�q�p��5��%����N��j~��}z�Ȟv�Ev�w1+o�<�1����.&��@�SŮ����pP؁�ej�ơ;���q�;S��76�a�E���8����9��N�����Q���&ǹ��
\ͮ��|MC��6]]���u�;ƛ�9����8�ξ+U�jn��T��sbþ���1s����������EE-�S�]���Z8�T�/J�˄��vj��Z|�Uv�j��}������k����~v��t<��(�[���as͆Rn�g��6��:������]��u�
;VW��r뾯h�7���Ԑ���ث���d��������Y��E������AʹX����μՃݍħ�x��:*m��;�o�{�rSou�t�9���|*f5��c�9Eֵs�[_T��1����Zw��:�sq����傝zb�N���D*O[��"~@��	W�݁�{�v*? �D�iw JC��:��Q׽j��Uv��>�`��8���w"TL-Y��P��d�Ւo����t���ݞ��́n>bv缓u�K�Qv��)3.:����Yz�8ЉO�ں֓X���.e�7	���9F�~��f�1s٦��6����9�{�甹LSר�5��o�ǘ�yߝ3lֱ����U?_f"ϝ3L��y;׼:�3���9e�[�p����,���c�f+~���L�K���ܵn�U�b+�?����-�_��r��:�Wf·�3fw���X��W��@{Nֱ��=��^]2ol�q�����3���[��-r��>w�w��˞�£�N��C|����@��`v�%�mp�ҁ<�v{P���[<�A��=����m�ֽ���;�Kcr��.���;�G�*��z�hX5�^¿�K�\���0v�\�i��;�ޙ�=�}�a@����U.�Sq�h��《g/+����=3{�E��=���b���U.�S/�h�O�����ؽ�;����.T{�Um~�L�8���� M�e�8����u��K���p�{��〈PE;=��}�Uv�i=U�4mP�e}X �w�7ٽ�Ӏ�0/���hZb�v�6��b������i'��=���O{�~g�������~��~}��7,S���ްi@}�ou�k���߉���}nݫ,�ݘH]���Ҁ����Uø�$;U�D)���=�ۍ��%��-�؈H]T��0'�]�&��|�Uv��	��-��^1y@�&��[�R5�[��v�&�Z���v�v��}�k�zP}�-ϝ��Lwz��
����۳�.So7Ö������rs��d�������m������ȶ�ֽx����(��l�j���A��$p�3���uT��k=��|�*L��o>��Ya�k=P�l�Z�2�Af��z���bWD�@]v�~QY�@e�]&�<�yL@�3ѹ�Nï"�AF�"��{�3,�������*N(��l���0A8D�Q�jUQ��b5y@&"Ȋ�t�l7�ρ	}أ`q*�K�ɯW��-V����T��f�i�q�(+Lд̔B;�T|S;�{l︤��H�f��0�a�٣��&��i�v��8
v�ߓ`����g���@�[��]�����#���:�5��(c�Y��z�lv��6 n�[&��=Rճ�����CEY=��;.Rq������D��꜏�[f�;�q���2k���5as����Ƀ_�ug�8���v�Q�:���v�Dl>�*��ZDj��f��D-��w�g�f����N�n��u�_��їn���7�.��-\{}�.�[�ۭ!�Cr�m�%&���$��ve%�U%��Y��Wu�%�ź۝o��LD�/�^.Ltn�{�l"�QF�V�ޙ(�f�޷ѹآ4����Q�}=4��Z�r_AT��������(�����DU�؍]w#�'YY���*S)�۽V�Y�(+�W�a"s�]�f���22���*�?t����"�Q�YWu�'�sn����Q�$��+��0~��]�f���S�`�
��f��U�"�U���z���m�k|s����9����O�	?Q5�"sS��~������1>�]g����0�_05����k?���~3��}�y��5�N��L�G�9Nֿ�q�\&���{��\��\��3�-��:�gc�}��{�=��s��]���p���VW�A��۷��c�9׺z�Y��\Kr��wrJf2�X��_y�V�^��˚��
�^%�KW�1�S-��X���L��a�X�թd��~�u�a�J0��1�xk��[��t��K�8.�e9�M�d/9�3ݪȥ3V�b7JzP���M�M�°�i�}@�c�3�7�?L�<�����?5�V����r)��f���mv�S#򇢛eS�����b�d�j��N�@�x���,�t�S#~��;rS���x���v��ۓ����NԈ���{_t�'Y'���ab�~1�#�Ԑs��q;��	]������F�uRש�ib�~�3�Y�y��<�A$s��Y,���F�u��gz��Zrvz���>�;8��~o7c׃��]���@�qX����P�Z,�`����yg�i݀��$��w��~��t�P�Z?Ϻ,`߉Xo7K܃Y��:Q����p��v��,7���uh�8������`�x��N���@��C�nx��>������q����f.{0s�����[��C�v��=�/��{o~���8����͜�`�t��=�L��]Ԕ��}�3�>��]�b�AĆ����.b��w���J���b�����Dl�U���N�t�
.p�KO?��Ͷ81Xw)�O[��7�]����=�Ρ��m��6ѝ~qƾօ�����nvC�g>�.�ZK��)^������x�S�r��v�����?��n�z�"��p�ݩ{=S8��:z:�;�i�o�p&�v�-t�t��/�ժ��2q��u�x��b��>��Y�^�TU����#�����������ǃs-������t<�����><����;�~󄗞�s�������6v�?����Lj��Uv��TE�]��^�:�i�uD׮��~�����ͫXչ��:�<���pη���MK��h�i�X��	Yд��o���A�[�}og��<1�����x�Ӂݷ7�z�pf�v�t0w�ߛ;�⁦e*���<���p�{qց���&����Ǿ�;΃���������mB{�yp�{✏v�{�������G���h����1�p���D.*ڝ�qH�&�\�����̶xD[w7��=�ۍ����v�C"6�#y	 j�/=�E-Ґ�El_z j��'Kvj6�Z�z��K_���]��ݺӹe�#ʼ2E����ר�,�s�B��x�r��|,3��\�5'��I�N�LU�\�����L�k��F�O��~}���S����U��d����=�}'^/v������~��&���������'Z!W�����؅�D�O�B�&Yq��n"�0���]�����+�d�L��'��Y�_������F    |�r�~-߿ۺ�4�A�6�k\�|�fv�a���	WأR������5`�׉V���N����K����L]I���:|O�®�����X��s���r�Uv�b=�n�^����p�]����vNn���;�rrx-N�vQ*7"J�SSV�ͯ�Ǹ����WE�����1�3;�ޙ)n]����ktrEo�����Ƽ���Ryj��ݫݍy��ifkPg]`^�.۝uy�YĻ}���������ڿ^����J�jz���ݍx��6�pM���e��E�����A�X�-�g&�<Q�Qe�A,��6�*��'�G��E�YM�{%d�����N��i5L���\zt��Sy��:�.yv�#�SU�^r��k'��o#�n�fDN���~��~�"Ϭ<�g�ɮ�"���h�f�%^/~�;��552똔��k���%�=^Ҁ��o���s����M��&p�p%6��s��~��]��]'��7�sn�yvU�f��>�0�K�=۬ov��,*�˸d���F��~�~�"ӎv�>y�s��/�v�gr�v2~Du�[�=�|��x�n���!�ъ�;"(�`��x�^�Qƕ����l9`�{���T��]b����� T�QUv�=x*�U�ʩ�͸��{�z�6�S��ui�}��y��̛�%3ovg���#�*2o��;�73)�i%o�.�|+����ծ4���?�*;�D4>�	����.��R1�"�]�-�Z��"Җ��iW陼V/��QG��l�-g����;�A�+��<Q?�%�u�,�~o�=A3"#�Q������!9��ȕ���sM�yϲ+/m���x��,�~��mw�9�d�Ϫ&�[�TV�o����΍�/P�Dl�T*���BWG��v��#��o�(�t��Z�t��Vb*�YpjLlJ������VO���߫i�$S��ƮbD���ɺV�����y��\M��L5������X�ٙ�w~��W��/Q߸CH#`EX��=C΂��--f�����n�f]����[$Nyv��x=�fvM���}D�<�������V�ݠ6����v��!5'�Kc=ߑ^����WyΉ^��
�(�M��1�첛��;Ͼ��:��ƚ�E�*x�s��뭫b1<j��:��:b�P]�Y]�;Mʆ��9v�Cv�jna��ܱ���߁��_z��~�,Py(hW��d��ⱫB]��,7��h������,�-]�]�l��6��
3�H�~qV4�G�i6v�����p���%U�/����X��2�KC�%+ꌟ%�T�UWi�d͉��>�;YT۬�2Ri�TJWo���H��R(�,��[��2_*�8�l�@ ��2�*kl���=J�)nb3�躓�G�Lq�^o��99�m�#Sܼ{}p��/�>�yUShz��r�͍�:�H݉���1W��;YO��o����_�;�[�>��yF{#|����<0�J#_GWf�U���>_F�D؋Ŏ̳�v��xH�p�G�Yy�m#���<k�Y�H�Wq�c*n��b]�;o�yLǠ`W��h�w͏�n=V��J+��;�c����O�W^�O����+ʤ��9f^���g�ň9���xQ�MI�S��U9̿Բ����^"vVo�"�)�8��j㵒w����n�H*��� v�G����G��<*w�c�yZ�/Wx���A�;��	��o�ӗ �ׯ�������^�Yt��w�N�F�)��:w���2���#G��:+t��*��_�Ǯ+���'���3��)~2���OG����;�_�k��Y!�y��`��a9�C�8���\j����99���)f^�ؘD79�kM��/�"sTen%��r2��%�I(�$�\'���+2�AUf�QbM�3�4)7&�O�p[����ОretO�Vry�9�1���}��l�JSr�h�h����yi��1i��/ښ�C���� wx��m�!��:k�.R���d��7�6���8���3OЅ1�N�׭����������;��x�faD��\�-��y����>Ƨ�� �$�ȿ��L{����ޥQ��Q�N��j�vG��sԴǛ�I��^��ǚ:^]���O���س�Њ�1Ӟk���?�o�!�e��&����c�冓�)9���Ls��m�����@�#��V��0���j����l7o:؝9�g�j�<���~��:��Wx%�Au1�m9���3O�����<'0�N�R3� �֭j��L;�c��D�Q������w� �\�m՛�#��6���ډ�J���e���u�}r+������[�x�f��+2�1UF�U-v��NC/cȅS��hΫX�!� ?�m��%��~�UCκp���m@ڼg:�ǻM�[�U$q��E2hf]8TX�U��&i�jH���[�SH/ō7�s3�.z)��"�G���!r�-�����O0"���n�N!}$��4�Y'�HE����	F�J{)��)��b��yL1�wܷԘi�8#��kf}Z��b���x�|�\e��� ;����nG�9k�-��~��vJύpP���C80��~nh{�?x�_��J���kRk��u�Κ�V^�y�7znS�7+�ɟ������u+���_ȝB��?�����#�}��˟��G^7t�}��[�;��γ*�T *��g+켳>I��s�֮,Rm�uӔ1��b�ժ� ]�<�8�9X�[�JRu�]�#<�UGk���Ѷ&˘z��g���yV�Y����UGkja�t��$�Y^kWq���G|��­
0�L�;�I�+�C�f�F|��;R����F���V�<��ۋ�c��W�U{C�Yy��i̓N�`�>��3���ËyVUkO�wL�y�}PsM�;���0��Wk�hE:�\&�����e�yo�8������#2��>��~����U��Y�g�=�-&���=�~�3��i霈�if^����Q��F>-Pk�Y�Nc�)?�,3��2��*j�Fb����p�>ݬ�2�{!߂����Rw��F�H8:�ݬ�N����%�F��f+����z�F|�*o�3Ld�=�G|���V��h�]�y�?� �jO�_4�7�KV�3[�V`���!;�kMz&[�H���N3�EVԙ?7��~�/']�?���x[�8���Y	M��ݘ|^1�:[5�C�x3f/Zd�ZG���3"���l�� �����0����k��A�V�>|��"�;Ro�yf�1s�b�˪�!5G^�����cF�z�cu7�qG��q����Y��³�["�/s�yv	�67�.�m�W\jڦLA\��R��mZ�zς�)[kO7u�oQ������jv���?�e�[v�}�N�w��`W���2�/�sI�\�w�����n�/�7��U����ś�&�w�GŹ��s�O	�s�n�{v����
Pq���~9V��
T>��Bje�֝ټX��W+��m�w۱�lU�	W����r�p�|Ái�@���V�-	�/��ʛ�#�L:��9��ڛ�lU�x:v���f��*��f�!-&�k�n]y~�/�e�����V�p���6�i�t����L���u��L�*o�*�mLBT��9G�u��?«��:hU\�
��8"�8�fM}!�k~D���d]�ȴ��Iv��KVz%�b��x�gk��\t8�ś�-��S_z�
���F��'���}/�$��u���6�������m�P��8 �t����>նT`��վ�U��;-��ky3�p���ݗ%g�%��D�W��ފ�� ��K�^�p�]U��y��q�,�W�U�� J>μ���?'b�{����m�G̼�ٿ�f����^�Xx�t���u�������V�/3��ךu�Tk���!)���l�)#��wۈl� '�c��n&�O��n�ތ|��6+��uO�Kڪ�"s�<%;(�V�u[s��\7��uФ����{����zȺ�n�I�����Gx���,O���R:����K}�u�֬'�1ʛ��R\E^�5��M�.�=��t�u�#�%���2�WWL7[�@^3�ft�r�I��<߽8�w��Ucy��-�Ai���JJ@\�ygݘ}�x    �������s��r�5�z��W�<�A"����i��ː�VA�݉��9�9�,zL,� �xOgQr�oy�#)����W�����P�d�����W�+�����I���t�5iet#�����Wώh]�o�{n�%-��<��ϛ
#���^��yG�&yݲz+d�d9��K�m��������i�:��b^q���֧��Ԙi��C�;E�y1܄�:+�3ǹ^��Ty�C:�T�'=����W���������7vdW�Sh��R��ǚ�d�M!����m����.�W�1��JnEf�yT�2<E��ڃv*ho�1>�r��"G*��.�A��b�ݪ45'ڛ}Dͱ���J#od^o����,�C}�w����9���ۏ�-��-Ms~�g:7&űN�̳����y6%�\J��̃��h~�[ �*�n�����)jN9������H.=��w��Ws����6k����j�ꬢ�fe# �6{��*=�kp�H<ׂ4&A8uX�$H65MŇ1]s��f��"N<g���]>�呏�3���e��~�g��4�K	��>�����۫�ث9�D��5f��#jN���9���X�i��Q�=��@{\��+}����N��'��s�y�f�����f�P!o7�2&��͆+2ž����W��\J&#!U�kM��p��.%	�����Wϻ�Bt�«��}���N\��y~�q���Wٍg]D�y޳n��}�����̓ %�����wÅ,]E��3��*��>G&�\�������x�#y_��8`�i����p�K�?oƳ�y{���:�'���VZ�Wϻ἗�����w�zލ�|��k�c�p��д�����v��nhZd.�Z�E;\e7��	9��}���W�m�]w�N��jC�#9�������y7�M\���Z����n��Lȳ��o3`�r����;��W��U;�ξ�DϘ~���04�o~�����~l�������������������?����7���_����?���?�i?V�?�����v�h����G��z�74�ַ����]'���2I������q@�x���J�/P�?φ#����*�R'��S'뀝���LK�'�za_f^���.*�����!�tUT�W����*�]���{�x^#��=B�/b��>�8b����������cczkU%v������4L<ϝI��H�Q��������k�'�p�s�庼`�-����1�L>�b�M�o��(��ڢ����vγ>4	��3��;�o7�ێ ��7��Y�{:��M������8,H)O�e����xﳛ�@�s^`>�*���;�������y�5k�J�N�q�%�i��_�I��M��X�^��x�e�7j����<oU��}����7����N����n���u�����|�uC�����s�=6��wu��$��)4�d��7�<�*	[�7�:�&@u���}��{l2��@E0L���t�����w���x�!9l�=6�|�}B���p�`PǷ��ڍ�<��|����q�g��.�<�P%�*��Z��q6�K��i��#��}7�:+�R���3�
�[��.��έ���!�| ��I}�Q/���o�2❽�׹̇��ҩ��
3O����-��cMK��ֈ����2g,��ּ)R%�)�=�]�ؚ�F�ļ�|��Jl9� �R�\���<�Z�r��2����v�U#�a�\¢z6�.��
��W��Z��bTK���=��� ������Jb����W��ւ��%޳.x��p��xօ����sLw��nT�����t㥏�̣��Uv�� IL�F�6�_5�9��Q��H#J7���m���"҈�r��/�h����q޳���h���_5�9�;N�Fo��+-��;��8���_��v�C%��� g���w�9x��{·�,���YM���$^�k���UvC�&��<M�I��Uv�~v�R���a�4��/Wn�ۡt]�i�0d��uI�VC�]qK��*��m �x�&�^���otz'^�p�&��U=o�� _���H�p���I
���*ˮ��j��-�m�yݠ�s7h��qV]4Jp�y]4�s7hi�wn�-V��^�`0�Uז���I�/1A���b���$�&�^ �y�<��ڣ5��L����tS�V�q��Moؓ>Li���K����t1�\�o����
N��%hN���`�T�A�	&d^��^��1o�6�n�W.A������n������EN�6�UkI|����fwh1���$�vBP��	�_!Ə�?�C;���3!��S����g5�pSߞ	�o�}y:w&�����3�E4񽧳�q7�����,G_$��{i�1C�MHN"�9�<}��Uϴ�_H�G%��yo!	o��g74�G;��shI�߅`hP�����<m��N�
E��h2Ԩ���7�&Swu�f�1����,&�B0�Ʉ�~Ҩ�}�ް*��F��<�S�Wx{�G���]�m�����W��3��fjyq�c�tg��ջ+C)���,fQBT�4#u���q��"�/D����.8�i-:�e����QF�+#�|�y�(���;�R����.;�d�T��)�]�<�e睔�:�,*��z]w�}�~�|8ç�3��y��m��+�K���|�������U%Z��	��%�z��'C��<�5 ˡsL�\�v�y���x3!sB��J�=�,'������01�ϝ�Ug��[̿Fb4���j��A��ޟ��p�}��{�V���}��.Gܽg���P�@�x�E8�e��Q��L?�ڹ2��U��]d��8���o��lP�ܙF���J�$wHƾr�y��5�ùN�JAfyy#�;�YL�d�щ7��\�ʭ�Nm��;�Fڜ�Bs��S��Z�����ڼr���,��ʹ�Yv��m4�44��|�JVl�4��[�4m������Rй4�(���x��d�Pt2KF�'x�,޹,Y8O�_�'9^|�wzArA�td�w���ё��B�q\�Etx'td�tMF�ExA4�94Y8�L�>�M=<gP�=�tg=:�$#yK�X�T�,Җ�N%Ɉ�/��;�$7���92�(����N���Kb�=�����5����xg+������Evs�ּ52w�k��	x�������xgd9�33�ŋL�NL��*褩��y����Ιz�zPu�'d����uq>ד���iK�,��gxg-e9[�3I22[΋$�N$�r�\'\gd��p�o��|�����|9/V�;U+�	s탔����R�>:3/#s���<�ļ,'�u�PF&�yAC�9CYN����L��bļSĲ�3שq����yg�e9s]��Ǆ���Gq�]��N�N��Ȥ9o��;G+�Is�d���k�����]�S�ڧ2#S�<�Jo��,���KeF��y&���YN]���ϴ7��^��E��&$���\Ź.0���Pԗ愤~ڗfq�!�D��$������!7vJI�F��������S�8�Lro�(�2!s_��7c�}g�wWQ�	��-�wWq�M��$nQ�
2�[h�
�y7e���Ei�	�w�����+\�;-J�LȼS�����=�y�%��6���_�?�h���|�?�� q����������:Y�]:��ۻ☍3�����
Fn��$�*w�$7o��ȭb;���ܼ>#���]%��Or�,��o���ϵx�}�e���&�>Y����`�cw���x�7�n��m�]���\?�ڃ|�{̶e`֜�!�An����>�p���e4���zhϹn�{_��yF��1r��[�K�vO�e`�s�̃���D�b�{~iy\��:��+ �1��y��nҸZO9�������{p�}��B�XX�s�;�t�>E���W�ݞ��sٗ��RϽq�s^����]V�q��9��{�G�)�c�h��D���6vK��˾.���֗�$�?�p�W?�9e��i&�<��[��g�Hq�|�܃}��;�!��    ����{�j6����U
�M�0f���+��f�� ?��
Ɯ��y/��؛<�!5��j��kIT��wcf����{�Ǝ�M�:���7�v9���ά��
tty�����{��S	Z[v��q�ڛ�s?W��Gb؀�6�Q}j�֎����YG��؃���`��!ߞ�Z��v�������q���c��r@�oL2s����n�V����B�؝�VC�B5G�>�^5�b�So7�v|�/�O�~<��{��@5��s���Ҥ��W��@%��ؓ_i�uLŵ��O�W+�Cǳ�섚�v�:�=�b�����[�؋�;���v��0���KV�γ��?��5/ح:`W�'��-/w���YdW��m8nz����[U�J��;}���]i�Y���'���؃��Cv�y���j��ێ|0-�N�u����e���A��g�1���~_��ܤo@/z�{����U� ��c ��y�W�9g�[&!�޼
��άƤ�i���_xϺ������5_��B�8��&ܻ�:'�I&�}�����C��[X�`�v�}�/��WSۛ�S�W�<�B{�/ξ���!�d"_��S��ۧ	nn1�Qo,V�������шZk��n�>ũG�9	7���ȭ�m���F��o��fu s���x#���_�S.~�)��R7�;{����M�L �W��k�p��d��!�TyC0q���6Zvdލ�ٗ1S�b��:���#���F_�|���'�	���n똹��n��!��7^��m�^�����d��/��L3#����2�����Qh�O�U{��i����f�]`�>	��v��j�|�t�XUf����bOCz�ZZ�$��o��9����u|�Y�;Re��D���`Uבjq+��6�ʊ���������Ru�u-C�^E�1�a����1���}6�*�*+�Gz��S���������mļ��MV�/�ix�<�]ik_�,7�M;��'�}��n��V���f�;���䏥� 7��ۨ3�۔�5�
d�G�KK����}�M6Y9���f�Y v��=����yi�̣gy�)7�M�ۡ�cv(�[�sO��+���jO�`u�#���v�Uc�c0v���2/�>���廚1�נIf^���>�8�¥ê�=I&�G�A�'[n���0O�y<_��Aؚ_G�y�1=��}��* a�<"r�Y`�뀛,��#'�
�� ����.r��伦�mE�\n���)�+�����[OA��.�w��Җ�J�G�E�խ�>��߷���.*�V�	�,�)�4�;X��[~@u9��{�QѺ
,M9���hҘ�
1�n]���:o�qLg�tT��uHgo_r������5�
�4.��9�b�q�*��^<o�ʘm�6.�� �=�N;�n��Q5X;����U��v�[}H?	���;E?��=�wx��J��j���+E*o������*o%t�n��<���I�S��������[.�b��{4��r����l+���yOt����n���]C�B����:��y��qLﻜߵ�:RU籏�h��;�ʠv'x�R�ؕb���BK�_*<3�1^����{�i��c��?�UU>�e�i�y�*y-�` ���R�L�
rk�������N��~���3&�G�[gqD��AUe�I`����)M���bl�Vm�Y��i��k�V�0��g��*�ԍsU�i{P�؃rx�ˌN����,�s*-�P���sOL��YE'�5�����$��Wa3�V�2����Y�>�?'�}���f�����j�u�Wl^�<��D�b[�Ȭ:��`L7��U7�;��;�c��d'�5��t��Ǹ�N�lMyA��=Y�=��o���r��f^�c^lM�Q2���t��nw���$V�����!^袃$X=��۝�%3�jo�ҹN�>�O<����9L�d#��y�fLF$[5G$���~��&�-�5��HlrօK�u�#Uv��˘^pYe7&ܐ*;��6|~��r�ir.���o����Pk���z���?�6�O:��6��$���m�ɡ��A=��<YW<���c��&k��<+�/ͳ�=�^�����<��1��|�����VޤO3�#��7�#���9zrۇ��V��]��݆gX{��:ϑf2�+��U� v�o��ۘ���ح
�Y��l���egk~�4p��e����y^�t�i r�-wtdv�WqNc:ڞ�͚]G�y�}��t���;�ϻ��1���ny�"Ӭ��1���!ܚ������:dG^T۳Uq�q+�Y�y��j��Ìt���h���ow��J�SsuWK�!�y���ޛ���z|��uW^���{_^M�o�o��s�f{f��[�5]�2ͮ�Me�x��3>B���3x�=�S�������:��~-S�}�^���[���15n+��uX�Â�aО��JdF�y�/�d"�'&���`�p�z��i��J�A�i϶���~n+�؟�E�#�}7ǆl�.!�<�n�@��o�my� ܼ=�xғ����:n��g��-��o��4�Q��o�O��K�,��p����)Ǿ���� n��]��-�-��p�N4��o�m�5`�-��Z�O^���n�^K������k7O��K��[pz���ג�Kf��sz�v�='�ߒ��k7O�%wG5�m�5��9$�^K�{ʵ۹L��� n�	��-���p��Ԃ�ƾ���� n�^���k���k@g{���c6�}�����k7O�e��5�m�5��8�龿&�-��p���1�ž���׀����k�}�N0�~vc�
��x��p��:����]�����	8߼�`L/��sVϷr�/�W^(��Xq�w`�Ÿ������H>�)��m\����5>�d���p�V��\�u���T��w�����������KX=߳qX ���-�m�I���m<�P��ű�<�7�z��qX��^Xr0Ғ��:�Qzo�}����]���X�^�eD���׊��� �����N�����7��}3��}���W,n���rc��^x���۾� ��c�>���d�>7f���{��Щ	x��"��w��X�6��q�r�H%s���^���lX�N]���X�6�Z��|S2���ܾ�V�=���7�=���3	��m��2�\[y�խ�I�Un�{lB�(]gl�ϵI�[ud���]���4���j<�'��^y���}�a���[&���;+M�����^��؄<�x�1#g�}���wX�ܐ�x��m��P�co`�[���2�<��T#]�z����s���-�M��@}�-"�:���9ޜ��"�%���� �x��7�}�E�I�.v�2��{�e�ݜ낋�/IQ���Kf�}}�ϵ,�k7�.�;�~����f����o��;�����_�y����y���%��
��UH~����>_ /�W_4����I\��;t�2_}�\�� ������1�����n�����9�{�]�7��ԥ9��yw_�gyɗ�H�d?ϗ�m|�}{�e��y�-��-@}�9)��<z�Щ@�e<������tY���� �s������x�:�뉁�S�s��"�zR0t*��y!X�H�b�����k��h�%wG#���K��$��3������ ��1c_��<���C&�*���3�����~~\��C�y`�ʫdw�����9��y�T�ϗJ�Un����G�Y��!`��x��-������X�6��������~~\�r��ӌ<?����%�*��[������~~\����
�Kx����B�UnC���y���Z�M��o�z"χ,���	�wV�+�\���~~��oC��k�����X=���^�lV�oM��`�|�����~�s�r+}~�#盧��|�X�V�c+ҿy�s��wN�=����K�|��ײ�����N�{�~X ���ۋ~~{��oˏ�W�x�����'��B}{<����3(����|Ȑ�͛��}c��V��+ԯ��W�~����o�9߼�#e�������YL�����/7����_C�y�%��_����n�<��    �+�-�5��d���L�~�-ǣXss�k�*���V}����&��ƽX�%7�d���ܖ>�$g�>���r�nY,��p�t���+�-��p�����+�-��p�����+�-��d�������r<K�=M�,��ܖ^{��t��ݸW��Ӽ�� �܆N����;gq:����� {�o�N����fq:ᾄ���m�T�/����r:⾂��m�T��
����S!�+��Y܆NE��/�;'�*����+��Yܖ^{5p���k�|%�`�5�O�
>��r[z�!��Ϡ�m�5��
~���׀��K�+
��m�5��
y5����+�Zܖ^C���+iq[z�Ӽ��� �ܖ^C���hq[zᾂ���-��_�_Q�UnK�!�-W���-��p_�g����}�=���k�_�|�X���}�9���k���,nC�9=��!`���k�|�,nC�A�W�!3���� �+�B[܆^�|���+�*��� �+�JZ܆^����;gqz򍽂�� �܆^����fqz⾂���m�W�G��-���^�WR�UnK�!�W��3�����+��Yܖ^C|k���kq[z�_��Ϡ �ܖ^C����aq[z����,nK����� �ܖ^C���3hq[zᾂϠ�m�5��
>���� ��K�
��d�5��
~{��� �K��Yܖ^C���;gq[z�o���� �ܖ^C���fq[z�ۻ��� �ܖ^C���Cfq[zᾂ��m�5�'�
�T�r[z�������k��S-nK�ܗ�	�����xd�^���k-�c��q��Zv�_�܆^��yz-��InC�e���yz-���V���q��Zv�_�܆^��yz-��InC�A�<�����$��א�s^.S��ej���q������6������В��k@�����s�[>�7O���KnK�!�<���,�-��p����O���P���G���77[>�7O���KnK�!�<���,�-�ԁy>���'��IΖO0���k�>����k 7�'8��KnK�!�<���,�-�ԁy>���'8�:��q����O������k�>����k@����}�[N�l�C�<���,�-��p���쿿&�-��p���쿿ָWK�u����f���V�_-�p�^+��k���k7O���5�m�5��]xz��ﯵ��j�5���׊��������k�Mpzɹ/<�V���Z��l�@�<��o ��q������6��ԁy��?�`�u�b�@�<��o ���p������6����k�����kP���D�|�)6nC�A�<��o ��q�������P��D�|�)5nK�!�<��o �-��p�������P��D�|��ց��o q����������7������k7O���HnK�u`^�A��7���m�5������$���n�^��7�ܖ^���|��o0͍��k7O���HnK�!�<��o �-��Cy��?�`���b�@�<��o �-�v�;���������zh��$�|�iiܖ^C�iz-��HnK�!�4����$���n�^K�����k�����o�����q[z���o ��^�_n�롉�o�����*��k 7M�%�|���7 �iz-y���^�/��&^�A��7x��J���<��op�Vz���5�|�#��k���u���7H��o`�[�5���׼���J���<��op�Vz��|�.�x��;���r[z���5�|�#���n�^��78p�|���׼��ܖ^;_L�|��o�V��^�� �E��[�Q3�AUf����@�9����f3��n�k0}��w��&��&sl�`:��|^��s?�fnz\�ܗ��S��3s/�fn�LgܗϿ�hʌ��f3����e����S��3s�f�*�� f�"c�}Ĭ�����8N��3�̽3���p���2�IhR��sfS7U�����+��6�NQ3��l�V�չ����6���ԭ�S&$��ܦ�)j枙I�2��,��Xޖu�̦n�L'LH2��S���2��i2�W�Q�Du��CjC�)��6�NQ3��l�EuV��dj�ʨ;e6uS):�`B���m���f���M�蜂	���0w�l�RtJ���C����RtF�eR�6��w�Z"E�	�P@��[>A����N;��e͵��t�	s�k�����]t6�y�Ӽ���l\t2�9��8����s	&���8��~_7m�S	0j␀�}-�mx`�"?���6uS�:�`B�y��ԼO��)R�G0!>q��OjڧM��N#��0^�'5�Ӧn�TgL��/ꓚ�iR7���&�Y��I�����"�9����|��M���	q���|R3>m�Hu��x�">�	�6uS�:�`B&�y��|O��i3�?0!sʼxOj��Mݴ�N��iڌ���!��̀Y]^�'5�Ӧn�T'L�#/ؓ��iS7E�s&d���IM����"թ32����fzԳ��ҙ32�Ë��&z��M��ā���zR�<m�Hu������<�i�6u�f:m�|^���<�Y�6u�f:k�|^��<�I�6uS):i�|^���<�9�6uS):g�|^��b<�)�6uS):e�|^��B<��6uS):c`�Ϋ^�'5�ӤM�脁��y����w��M��|��20�@�f��N����.p_>�Rx���N�Z�C���*��IM�JYt���L��;���6�ܨmΫ^l'5�Ӧ.���f�J�vR3;m�Q����EvR;m�Q����vR�:M�6���m�f��:�i�6uhԆ6�3ya�ԬN�:6jC�!�M�}�6���$��V�uRs:m�ܨm�+�b:�)�6u�f:E`F&y!�ԌN��i3�!0#�{��NjB�M�T�N�/�W)��Nj>�M�T�����=^<'5�Ӥn�{�N��)6^8'5�Ӧn�k�0#Sl�hNj2�M���:9�8*д5�Ӧn�k�0#�{�XNj*�M-�׆6f�x���LN�Z��mL��"9���6u{_�Ā�b�rR�8m����y32�Ƌ㤦q��m�m�i32���fq��M�謀�b�EqR�8m�RtR��L��8�9�6uS):'`F��x1��N����0#�\�Nj�M�T�����&^'5�Ӧn��0#�M� Nj��M-T��̀�&^�&5}Ӧn*E���d/|���iR�ɦEg��d/z���iS7���fd���I�ݴ��Jѹ 32�ċݤ�n��M��T����nR37m���֙ 32�ܤ&n��mWA'�ȴ/p���iS7��� fdڅ�IM۴��J�i 32��ۤfm��B�(mV�i^�&5iӠ.b�e�I �v�mRs6m�Rt@A�/g3Ps6m����9 �w	���@�ٴ��΂�(��G��ljΦ����:� �����9�6w{o�L���^�f��l���ͭs
2x9����is�w��(�H��ljΦ���[)���C^�f��l���{[gܗ��7ό���is����	(�$H��ljΦ����:+� � ���P�4�N(Pn/g3x�9��
2��މE�F�Ā��F^�f��(r:Bgd:"C�S���Щ�������P䄄�(ȄD x'9#��
2-x9��;;��y�P�y�@�N(rb@�(㈗�����������5��"�t�@A�/B xg97�3
����)EN�����b�w�@��:G� ]�$�����I���E	�,�";�u�@�Rpxa�;M��^z�&P�����yE$�,:O� ��(���׉��H���)PdG��(Hoy��
�T�"��u�@A��/V x�
�_�s
�_x��;Y��s�,P������E�g,:[� =�.����2���2�x���/Pd���(H�y�";�u�@Az�/b xg�u�3
�ux!�;e�Ⱦk�2P�l����9E�+,:g� �ׁ4�����I    �B�����5Pd��(Hr��ﴁ";�u�����^�@��XdW��X7��މ��c_t�����"�w��"�Su���8�^�@�NX�'��S�?�;�sٟ�s�?�<��ٟ���?�=��ٟ��ĭ;���w��"���>�@�������?���T�?�@}�� ���@��>M�@�@}�����A��>M�A�@}�����B��>M�B�@}�����C��>M�C�@}�� ���D��>M�D�@���(���E��~E�E�@���0���F��~�U�,P�"/� x�,�_q�yԯ�$މ��W\u"��+�"	�w&�"�W�I�@���P���J��~�U�,_��Ƌ%޹o`���kH�/� x',�oo��Էǋ&�����[u6�����	�w:�"��V�N�@�k�x���O����U�,P�/� x',�m�	ԿƋ(���_[uF����B
�wJ�"��V�R�@}\�����S��>�U�,P/� x',��k�I��ċ*�Y��gZuV��8H^XA�N+X����
���W��
�ϴ꼂�S�����X�G�U%L7�:��5�̂�r�zm[F�7O�9��`n�Z�-�L�؂��[��U�^�m��w	/� 8'�`���k�2���E���r�zm
P/� 8��`���k�2��������r�zm[�� ���`��U�^�m���a�3v����m�����r+��>.^�Ap�1��*��k����$������e�y��k�Y;X�Vz-@~{�0���f��Un����ċ3�y;X�6����4Ή;X�6���ċ4Ι;X�6���5Ω;X�6���ċ5ι;X�6���x��9�`�܆^C�zx��9�`�܆^��~/� 8��`n�n�-u`^�Ap�7��*��׀����7���;X�6���y��9�`�܆^�["/� :��`���k@�q��D�|��rz��|��o��UnC�}��o��v�ʭ���+���D��̓�ST��2�L�]����ܞg��[>��N=��03�e6s�h��c�=ɘϱ��N��}�SO�3��g��,�Y����y-�9�����6��5����ѹV9����S_�g��5��}s�������J�MH������D�瘨)o�m�ڢ�1��M��J.��41��Y���\�܂m��Q3�?6u�V� 5����Y&�U&	����,�蜥v|����yF��r����L9�o�@�&���;6u�(�~��8�~gjK� ��4jf��#j��-�[��Q��Q�WN�������KH��	�;X����(�`
j.�}��>��ݖ�w6����R`S�7�r�/�<�v�w�I-z5��|^��۩��6uS��	����� z�VN����w6�К�gm����V�i�����ޘ�nlS�w�rWږ�
 M�R�Om�ǻk�)O��2�³ʣ:���y�Nm�k )�g�G�ɳ�C�V� 5M�Q]�>�6�8Ѕ�3ɣz��ԱQ�)5m���!��Ij�����!����y�³ǣ���ԩQ�) 5����!���>�[ȳƣ:��ԹQ[���gG�����J���1j�J���}Hm��������p6u�1T٦�f�Det���a�،U}⍷uvs��<�}�:6p�i-�<�϶�O���N��>����� 5q��}O\P[�\���k�uu���?x��olY��*������}�LL��tK��ר��_(�U�!X��6���D��P�H�����RX�2��5��EM���Z����5��0R�mM*�l�)�K������nJ\eށԴ�Mj2���5�P����\���
Pͥ�����Vs�w��oM^815�ئnߚ*���ES��?���4��=������a��zsԴ�aj:��V��2�k���y�'G\�����/���Il�����2�@j�N�&�z��,�'��Ʀ��~ؓc�����by���6�Ҩ��@M�)�L���^���)�H^j"�M�6j���'=7�xnS����xg[�8۴j�g��g 5M�PS�?�6��@ge䍴E�L�y���J���`�sCm��mg7�c�u����UN�n��3GgG@=*�7���|��]*V��A�h�d7�l7��&$ɏ`H�/���[[�'`Դ�jz��VW)R�8�'V�5nuX�W+��Bjv�M���1C l>�P�2��v���P�y�ˈR�����Y�z0�ޗ�j ��ѧ�BU��)��v��9��u�Sz���M��ޗ��a�8q���3��|^�<�Ǚ�ܔ�1' f~J���gc��{J�3��)�c>��2����n_6uSb�Pb�s�}}Hmh1$3�9ݾL���ʲ��2�q��.~6u��͆Crҟ��˦n�;��~N���M�/��eS�)�l����<�חMݾ9�����a���PfI�Q;f�T�Jmh���h�6O�]*V�6�YF�֬�A�,�Mݾ=��� �����z������΅6u��,m��<��Mݾ>&C�M@��9}M�}}L�6�����۳��"�m�P?��އԆ6����'������m6=��9�hS7E:�l:�H�tZѦn�t2�B��ӊR�l:�ßԅզn:|6��$T=��M��lh��"}�	M��)���f �sNh~H�k�t�rf��sBSS�X���f �sNh~H�k�m�~N�a��U�^�m���sΥ��M�Ͻ6ۖ���'�K����{m�-8��(mS7>��l[��4�M�i�H��ӸR��l[��T�M�tx�ٶ�g>�T�M�tx��0���N�6uS���f�w��tצn;���f �s��~Hmh3 g�IgqM��tx1��8����6u����f��Τ��M�C�ilO:�jS7���}Ҵ������f�s�}|Hmh3�w�I�>l��C���O��aS7���}Ҵ������f�S㓦}��M�/�6��3�æn�t1��E��i&ul�t1�����i6uS���� w�'uR���"]m�S>iƉM��jh3���I3Nl��VC���O�qbS7m���1R���i���f��Փ�G��M���6�ܞ�Ŧn�l5��t���6u�f��� ��B�f�}�L�\��6�4M��}3������(4mV��͚kF��p�(4mV��͚�D���(4mV��͚�D����i��o&�m��HдYq�7k�
�fh3�U�дYq�7k�
�fh3�a�дYq�7k�fh3�a�дYq�7k�fh3�a`�i��}߬9���̀Y�����}�,T��̀Y�����}�6k��̀����}�6u��̀����}�6u��̀����}�6u��̀�녦��}�6��̀I䅦��}�6���̀I�gn�o�&�C0����6[��ͦ�R��̀I䕦�V�}�6���̀�ܕ��V�}�I��mL��4m����mL��4m����mL��4m����m�i�4m��9�m6�W)+M����fSS)Qi���i�4m�:�1���f��\i�lu�7bN3D��2��Ҵ��o��b�J�db1܈��;gA�,��-nv7�<��*�{[(��2�n<ڛ��Y|A�l�����F�h�_�~����ؖoi�	��y-�ɮ�r���dW��d��Wy��m�+�l�mpZ��hoλhALw��-��7�T��*���M:��-#�o���y'-����r�e��M�k�_�~����
ؖ�sbX�sZ�V�����sq�ηs^�V��L�b`�sb���V��e`&�s�sf�V��L�bh�sj�V��L�^�jp���*��׀��@pN��*��׀ɐ�K]��;X�6��?HpN��*��׀�p.>���v�_k�!A�lˀn����rz������!��UnC���"�Sv��Jؖ��^�@p���*��׀����I;X�6�0=xQ�9K`�܆^�7/L 8�	�    `���k��D��	�<��rzI)�
�D��rzI��E
�L��rzI��
�T��rz�4��
�\��rz��`���,��=�U���<�x��9[`�܆^:p/\ 8��`���k@7j���|��rz�������0do�NH�^�E ;�t�@Dz�/d x�Dٽ�S"ҽx1�;g ��5�3�~&^�@�N���I'D���5����g�Y�o�ﴁ(�[t�@��<xq�;o �>�7���މQ8��8��?/r xgDY�י�D�Ё��:�+bЩ���b�w�@��P�;�� /x x'DY������w�@��1�=p_t*/| x���UnC�!�^�@����^��"�<x�;� J�!�@��s^A�� �r�\gDh�B�S��G�)q��?���k�9o`���k�~*/� x'D����"��ʋ"�YQ��,���|^A�N#�r�[�$h_�G����W�y	�W��D�$�u"AB�/� xg$��t&A���x��;� ɹ9�J���5^,A��%HrM�$h��L��	�����	�g�E�l�$��t6A���y��;� ��s�N���^<A��'Hr�E�$�?�P�
��O�		�w�E$�tFA���x!�;� ��5�R�����)�9I:�꜂�q�
�wRA}\Q'$�g.�
�wVANsQgdđ*��
�wZA�TQ�dȧ�W��
��)�:� C}�����X�E�GԉIk�Ȃ��Y�E^s�)���~^hA�N-Ȣ�!�Ԃͽ�b�wnAs�Q�d�{�\�����:� Cs�����]�Ŝd������,�ǢN/��w	/� x�d�]u~A�ꂼ ���`�E]0���e�����a�V��^��:/� x�L�Nu����b�w��$|��1� 2^�A�N2��Y�I��xQ�;�`�zMgLP�"/� x�L�_1�4�	�w���<�I�;D�g0A�߼@���h0���&h.�i�3&1u���^�A�N5��nѩ3��ȋ5޹��WԹ3���6�����:�`��x��;�`�Qg̐� /� x���g0�t��o���|�Y��|��Î�|��o0�>��fd�!���w��,�t�����G^�A��7�ż������|��oP�t��y�E^�A��7(�=��
2/y��;ߠ�y���
��y��;ߠ�~���
�yy��;ߠ����
2_y��;ߠ�������>��"5���4�"���7�nP=���]�i;Te��}���)���U�{��1�R+g�}�ʑYel���]4��Sv����m��N9�R�0�j��2��l[>��)_}�CU�^�m����N��3̾�d��̽&ۖ�c�"�����}���e ���[�ۡ*s����ɒ��ߊߎU�%�8�o�oǪԆC������w��RR��2�H�����Xj�Y�-#�j4j�JߎU�E9tШ}�|��ɐz6q����n�L�l�@u�&˜3�v�Jm�2��ؒ�~_jC�!��4i术�cUjK��ף�x%�t��R�l:�Hy�J��J;V�6����(s�);�*�`[>�Hy�JιJ;փZ�l���(���[&��T:��T�xE=��21Ӫ�	�e�v�+���J& �y=�=3Imh3�?��䜦�cUjC�M@7���o65m�2	���ڌ�䜤�cUj���I�Rr�Qڱ*��f�{��(9�(�X�Zi���ym�Qr�Pڱ�*�`[j�4m朠�cUj���@�Pr�Oڱ*��f����䜞�cUj���M�Or�Nڱ*��f���E'9''�X�Zi��8�����s�v�J��Y@�uy�IΩI;V�6��n�Mr�Lڱ*��̀�$^d�sbҎU�m8����v���ؖ�k3^\�sZҎU�mL����v�Jmh3�{��䜔�cUjC�Y��$眤�R�,��f��$甤�R�p��$9g$�X���f@�/"�9!iǪԆ6��/ �9iǪԆ6|Tx�H��H;V�6���Gr�Fڱ�*c`[>��x�H��H;V�6�Y<��x�HιH;V�6�0�ɋErNEڱ*���j�6s�D�m̬�"���v�Jmh3�	��䜇�cUjC���ڌ�䜆�cUjC���0$�,��R��L�E!9'!�X���f��/�9i�z�N*O`[>��x1H�)H;V�6�0��Ar�@ڱ*��̀�T^�sҎU�m�PӴ�s�QGmh3`.��~�cUjC�����#���R��M�E9'�X���f�t*/��9�hǪԆ6�Sy�GΩG;V�6�0��=r�<ڱ�*;`[>��x�GΉG;V�6�0��<r�;ڱ*��̀7^ܑs�юU�mL�����v�Jmh3`N�u�t�cUjC�s���#眣�R�����9��X���f��&/��9�hǪԆ6�4yG�	G;V�6�0��8r�7ڱ�*'`[>��x�F��F;V�6��t^�����v�Jmh3`:�m�l�cUjC�s��`#�\��R�����9��X���f��&/��9�hǪԆ6�4y�FΉF;V�V�,"��@#�<��R+m��E^��s�юU��6���"/��9�h�zP�L�m��J�E9'�X�Zi��L,򂌜s�v�J��YD&y1F�)F;V�V�,"��#���R+m��E^��s�юU��6���"/��9�hǪ�J�Edb1��s~�V�u�,^~Qp�/��*��π����/
��E;X�60�x�E�9�h{p�L����s~�V��L�^~Qp�/��*��Ӏ9���/
��E;X�6�0�x�E�9�h�܆Vf�/�(8��`��Pk�\[��j~���&ے�
��d[ �x�D1ۖtZ@�rU���:��yQL�%���@�N�b�-�Ā�t��8w������Sҙ�z
�� �Ԁ(枒N�/��s��η��Zl�o��y�@�N�b�+�䀈L|�s��η��Z��J:; "�O������N���S8p�|�﯉	(��	���	Q�@���d�^�@���"�.����^�@�N�r"H�Dd"(�b�w�@�3A:G B�m� ���$�|�N�Pz/J xg	D9!��"����k�iQ���4�%����w�@�S2:O Bif�@���(圌N�P�/R xg
D93�3"���ީQN��T��{�b�w�@�s#:W "�,����������h���-�����E���t�(�(t�@D�(/^ x�D9I��"2Sx�;a ʩ�0������Q�茁�t�^�@�N���^�D��>�b�w�@�]�:g !iH�4����CJ:i !}��5�����Y	������6�d��NHH�y��！$��u�@B��/p P���n�1�8�/�����Ш��m	U��^jߴ;�뾖P�9�@:��랖P�9�@6��k�\BU�I/��S__�,|��gQ�9m�7e1{�K��\�e�A���G.�*�b,,f��q	U�Wc�}d1{�K���h��,M�x�K�Jm(1���'ż��%V�6�TϧQ{�K�Jm�1���\���#���i���cH������Ȑ�$s�7�X���dH�o;�k7\bUjC�!�4Y��k*�*��� �Kb���N�ĪԆ2C:h�̭�Tb�S��f3���k3u�2�X�Zi����5����J�J��ٌ|c�ZL�:L%V�V�lF�2y�n���R+m6#ߙ��R��R�U��6��/M^s�[o�Ī�J��ȗ&��ԭ�TbUj��f�c��X��W*�*��f3��k+u�*�X�Zi����5����J�u0���k)u�(�X���f��&��ԭ�TbUjC�_��vR�nR�U�mt��I�zI%V�6���k%u�$�X���f@�<��ԭ�TbUjC���6R�.R�U�mt��H�zH%V�6��    �k!u� �X���f@g<��ԭTb=���̀�x^��[��ĪԆ6�xͣn���R��ൎ�u�J�Jmh3�i��8��7*�*��̀9 ^�(�kԦn�먴YA��3M�e�}�"z�sTڬ N���Ͳ�YN�9*mV���L�f�y߬����6[��i�,;�-�r�f1|�+�ǂ�o������y��O�?�+�<�>�����p��	>���}����ý�xꖧ	r4��=��U�l,����;Y�>~�{��?~�{�/�2ԥs�{�Ш�c(m_����kN�r��/u��s��0�K��G�^�Mr��=^d�DD����%$@�y�_g���'��>����"|�}
�{އ�.3�Hؗs@�wʹ�������ɸ��&ӝs&q� �s�#��~�[z'��_NH\Еn靬�/�r~�o<Ki.ޗ�2����P)���t�t.t��d<���T��=��U�^�ݗ�����;Y�ڔ�z�{|'������JC��=^�*��///y�W�
>��W��+Y/zi��=^�*��-�	r���=��U��X~A�^����X~���JV���4r]���*x���%�3�������~������r�O��o��ß*�������&��|����&~_���TU��^��_e�b�&�����{�՘�����Ͽ�ӏ���*�o�����-�����g��?������������_�o�k_��_���{���P쌥O���1|�[@U�^hn˪���S�yԝ�z����s�7d"�ivA{�H��r@�G��3���\����,��/ț��w��_���W�n���s���?�Ϥ_U��ʯ�v�����8������_ߏ�����߽����w�e�����;G�#��WȆ���X�����r��ڢ?�C1F˯ʺ�T֩_^�&�˲����ڟ?��/�5��ĬQF
�jy.�������w����m$k�]�O�Ω�Yp�0n|�]��HF��U���q%WSs��=����M�i\���e~p��z�<Xz��˞���ҫ�dW_��&V��^=M�.�_�u����z�*I�zz�kx�����c ����T��/g�e���T֥[��K\�4\���0�u��z��u�y���~9�˞�$kk藳�Tz��e�z�M1����<��hʛ��/�Fa����SYs��«�:U��:���Uv+Le���lt�^��a*k�����5K�u�s0��ʺ�Tֵ_N/t^w�w��v뗋>u��u����[�,3����IZ�L�^7M�/���u���G��ܒa�v�������_�^�u:�N���)�"�t��:���U��+Le�i��m3lz�z�����ay��my�d}�Tֵ_�z//��0�p떷�Wؗ0�5t���5ISYc���z����SYS���a����$绦���|3Z��z^w��:�em3q���Tֹ_~�o:SYK�<#���u����n��鈈�����u��e{z�ȳ��`��~y}�Z�����[���_D�?`*k엋��xY�"����廄�zC���a*kū��(��8������u9�����bi�g>�;Le-zY��]���0�u闓1��5ք���M����I�xO�WOiz�nS�`M�z�Y��J>���	f���|$�5T*_����a*k��`֧�������Y/p%�{%�V�8�W�*�¦���
�@=��������z�+�H����s ��*%��>��,X�RR(�%�dI�멩6W��w���+��26���W�SY{%�>����zjB�BO}%�?�WR�2�=��W�*��s��`�\�G⃞
��f���5�0�u1�_c��T����O~%+���/�L��T��Y֧���������I/cՂ'��E�`ʟe}�+Y�N�2��s�+9���i�Z�9���o����'Xá
4�J
f�9�d��WR0��%�Ľ��,�.�.>b�a�s����s�+9�,�i�TL���_�;R%���}Yg�\�JN">f�{%�>��|d��z�+Y�z*�[��Wrv���+)�����#k��`�\�G�^Om���.9S;+%��>��|`-JI�����Ľ�J����W�SY{%u_�\u��J�a*k���˘#��_�;R%��T��;��|%�0��WRS����u������PO�g�k���C�Զ|�o�M��MP�Jj�>��7�o��?��|�����������Ot��=��W�j�N(��B�AE��)���/����ߕT��	�$G`����~�V�1��r���o�1���c����:F�����hُ�r�"�������l�h}?F������|���1z�pێQ�!P�K�|&��/c�����J�P�SrK6C�������z|�~�T��_?�LB�������i����y���3��L��w�7�ˏ���?�������"YBK��{)�k���â�n����q �}��˓�]�7�����7�r��_�w�\y���Yo�r������_�P�O�gcg⻺~f��!R�O��o5�$^����g�+���S��sT�ԟЦc�y˝>d¸L ���2T��/�(M�'��<�}'��������5�˫aP�]�U���0�}9�3Y����k? �x-�r4������9�G���ԣ���뗠>x�z�����&�ݺ�l��~��׏�~X�Q��l؅��Z�K=j���◈�7_�Z�K=j����wSh��Z��v�X��/�����ԣ6u��]@�����Q�K=js���Q���Z3�Z����ߡ����z��[�G���:�e�$}^����2Z����s�����^��'tߕO�"�����0���	~��N��N�>K|���{��sg��!���*�[�p�Ra�r�fM/{a?x�߉��_��靻��~w���<��^���Ǽ��Ƴ���x����׿�ߨ6�w)o�O�h|�\���yvzYw]���y�\މ�g�/qa7��;�?��T�+_�Y�1���]�|a��l'�]c�^|�����\׹�ߨ���Ǝ�󗛪�\��~�v���^�g��g�{�u_�#�_ý�U=�Y�9��+ހ[������M���2TO��/pI�<��\[D��u�Kz��н����W���x*n��6c�?�%��n���j4H_��QC���yN��J����������W��w����4��_�}�Kz穸�κ/���>�%mB�7q���b��^��^�7�z�u_z����7�:+-/yI/�ν�ʓ�yx�Kz穸�Κ�1�uaܝ���:k��u����;O��u���^�ީ*t��&�u�ʗ�4Q�s����zJ?�%��Sq{�5��w����x�����$��K��Sq�~ys6x�K�����n�ry�K�AU�C������{I�<7��ј��%��Tܤ��x��/��t�<�~9ɯ���੸���R��Oŝ���{J�T����+}?x*n��6�����y�T�^g�~�׿��q�<�jk˩}�=�O�U:�Ŀ�%-���Y��*�]��^e9m���f�m�<�%��T�^g��O~Iw���ږ!�u�Kz��н����*K�����r������~㩸��ږ_�)�SU�^mݗ���K_ұ�^gmF/u�r���:+[�vW���E�\z��^�>B+�U^k~穸Jg���~Iq��*����/�"b����i?}�Kz穸�΂q����p{��^��{�5�/7�����oT�W[p�Ƿ\���K����j���=�o�娼��v���j�Q{��Q;��ư���������zX굖��j����VK=j�_ޚ^�����S�<eP=_������ooӦ/�_Y�*t�k��җw���K��h����e�Sz�m�JU�B�_�ᯞ{�Rr�z�u5ߌ���\���R�Z�˷������8,����R�}v����8,��e-��!l���Z�e�c���<�h7�����s�l����R�K=jE�o��y���ԣ����������%��m&�ń���B�n9/F����;U��J^ �	  -��_�;U�>~B�-^��g0�B�~9h�E1����|�6�5tm �e�-�����.�������!T�����ԣ��e=u�w��ow��Ҹ]f��W�>w��V�0�u5���k|r֦ ����P��#q����P ;��ީ*t4�!�K����B��o[~1�JU��/�U
���o�A�?��������GyĨ��^�;C_������䔚� ��V��(g��ُ54�Җ�-�c��Q��K]��R.�r2I��nF�\�e+��׭�y�����rZACXN{��*q���K�m�N�#U⨗�CXH��b���.��`l^�i�cTʬ�u�zO��RNƲ�_��4�a*kSLq�ŭ�����O�m
6�Ĩ��X�ޯ�ݠ�o��X��A��	?V�$Z��-����7�e���3�������OA/Oз�S_�o0�5�������]��O�[��SyN��R�ny���G9IG���~9}	/��1*e��̉��>��h%���[=o��}`Tʥ_�F�.H)G�JZ���0�� �"��K��eL!<�3�Q)C���9�|=`*�Q�o�)��;����������?��?o?~��	����_NF��3_�>���S�I�����~��C�����!h�1O�rL�t�.������r6ƴ^����*|1�!1}��?�h���n�������ȫ^�sc/s��t��f,C��^�;c=B╷\�v���s�����~9�FԲ�;�t�K�{�FeJ�2t�'���y��W~�gp�ay����+�[Ӥ������ؿr�ϲ{t����|����v�K>�e*��jD�}�<���ʵ���2-zYgQ~��$�W.�UdR�i5��~���q��h�֦8��en�^���U��/���E.�]���2�����}��S������-Lï��S�IxЕ9��>v�-�n��O�?G���amxXGa���_?}�t���>��}�~���*��i�g����������-�5�'c���w���_�$�2��t�;��W񃱌�A]�8b֣���Kx�w����'��G!^�8ب�(
��=�����	�圾l�Jw�NW�g������z�|���WVAG�z�ny���W��6p������<���#SE��4��Nx�M⿽�ϲ���joZ�*��5�x�U��(�/܅��?�*�Q��[k[�ndxGk0���~y7q�w�x�Y��.�_�Ҵ�����2P�,S�H����H�x�W�q�Ǐ'^e�R���Nj~8�T���
�{K�6����㑪B�z�?)���E��X~���#U����	wS���AO,���_�������Gޙ*r���c�k�����qM�r�ܗ '���~��!_C^Q�8���a�u�S �y޺Þug��s��Z ��$�#s�;�k�g��E��2�����[�(��N@�����nߌ����}�P�y��`��\�����ۭ_����2/`���r��
�+��̫�Y\nG�U޾�?�s����ʜ����]�9�Ѽ���v*=�Y���#�E��r����y���"����/��}/{$���Q��8���t�#���#�t��f�:|�H�����_F7T�t�#!7Z�p�3�i�J�CG"k�%�~y�r��~�S}	@G���^7�b���H<��t$�H_B�&s ���S}5 GbG�G�טy2�t��.pY����#�k�\P�R֑`lA�#�%�K"������tո� A��K���ʯ�G��b��%�J{Z������*�QT��Ͱ>�l�Α���SwGl�~��<v�+^�֓���)^��ء�ݡ��o�r4Lؽ㡣0Xb���m~�ތU��zY�^�7�AU��^��������b.�~9}��l�k<�ް*��/O��D�Y�^U�Te���٨�}Q����W�,ki��x �~2�8jW��=�zԔ8.������7�K]lE8�,Q����-����'��E$�.��[��z�}|��#���~\�a��[##~�tK��I�G/i�?8|�o�"&���$��ȟ���_��YE�Œ�g��f�
l]���8���J،v��h��a9,o9�M���Z���-�o�I���a}�|떷���`��Z�C�Zx��qH��c����@�=�ܞ˩[�f�=j�B�a��!��	�&��qHR��I/c.�>���~9��]�=Y�,���3hZw��0��%�z2O߉��A�q���>�[s�㰃>�����)'zr�ǡד�K\�8LrTb���t�s�]�����Г��_�ۖ���χ#h=�[���u����_FC�.{d��R�O�Sy��#h=���嵷����8,��
]�8�rt��<���B7���q�Aǡ����qk����zB]i{|ܬ���n9�z�b��M���m�9�������o��o��t-X      �      x�̽Ͳ&9��n=E>�8"	�l����H2I���W*��*���l��s@�o�����߂v{*�"+2Q'ݝ8 xND�'c�q�7G�;�{�_��_�6��w���?-��3�O�/���c�S�_�V����S�_��O�[�����������?��O��˟�?��O������>�����׿��/���ۿ���>�뜆�&�PM�5���O[G��3�@�wp��-��tÞɄ�jٌ���Jos�7�;8���g$x�~8l��0`�`]�ަ����;����	�8�ux��M��%y���&R�5'Ǿ��3�@x���g���s�uF3'|�y�ڀXR{�3��c��<�q�x����#���ftg���eZ��g?��6}v}�L�8C�_A�7����R���ܿ)����������5��+�G~�o�y�7<��,���|���7a���_�������˿��8��ۿ`��o������F�ۿn������������?������+������~�����#������������������_�����������-�+�W��7��������/�����,�n�#��������P�p�B��d�Ɍ@�vr�̸p������/��hʔW`�Ť��o<�+i���w�����y��5W<����j<�(=��p��N9���8G�`FW�$bJΤ�F��k�s�;�����|�De�&Mp���h(��t=y����7�;8������}FB(r1e�_'顺VδC �N����[f�hZ���5~:�O�6rJm��<O:�<k�9����lr�b�Q��4��g�!|�|0:�!o]B(Ճ�|x��T�sq�%��[����}�����PiZKӐ'�}��l\�v"��󆏢}'�N���9!*�#��-���r���iJ\8o�(�wp�3�'��l���)�`=6k`�U8��p��Q|�7��쥎�*@��ڼ��M��^f_87>���3o.�#�h�i�0M��9�4Rr7c��	��,��3o.�#ϓgzp�e�!2\RԈ$t?#�I���GH��ys���r�l4�x32��`\�ԩ����<7>�g?����ϒgw<)��O��қ]4S̭���G����et��1�2�T�P)�2�<���Je�eK}.�³�_F'p����D|�a��� t̚\����w7�7�ё���fY},T�ݽ ���d[� 'p�w�� <��et&�/��o&e��P/�-�S�I���������̛��H����S7�pZa�B��<J�΍����ft�4�ят���5���2~$w���Y��?�}Qr܌���-����!^7L��LԸv���>����x(?��!U��n�{�{�����O��>���f<ě�E��X&�<� _��9N{��\87>
��g?����y�n=�Ł�	�:��i�j�F)^~i�#@x��et�ϗ9=2v#5�v��ڜC��')��a���(����2:�w� �v�w��@��E�S��I3�<N�w;�g�\FG�Q�rt��h��σ7����\q��¹�Q��?��et�^ר2'kFҼ��j�D�9Gu�
%�΍� �7������|���l���}�Ѳ���s��N=$���4q�	�x��Y�;��I�?�u8Ѕs��N=$����;���tN�mLF\g���(�hW\�7>
��w�Q<Ug(d-(3U��%u�I��x�wW��7>�Y�����aѸn�Qʠ`&�������������'��6gɆ���uŊԨ�i|xV�/��w�{>uޝ4��u���D�f�}J9Hb��^87>��o�3qB+5��S��(��Yˈ2��N���ϗN�8���c'���w�l!�'�&8_�#�_87>����"�/=�k�j��kgm7��>�{��m|�ߩ+�SuEsjȈ>X4��=I�!���i�y��(���S��t��!��UO�'��3�4kɓ�/��3-�#ϳ&O���F~��^�d�'?�(��:�������>Ɵ��	���[A�P)��9�֒�<&���<?�Bx̋/�#�djb�e�^�a��C�u��:��H!<�q�ё<����Έ������wC8���.�<�>� <���??KI%�E��39֓��l R�g^y}�#��ț���l�����lY��Hd">Ζ��+Nw�y��]�>gB®�B���Y�%��z�#�<.|�#@x��^FG�;���ٸZ���j*8�Gw!dc�Q��G
�7/�3��8�8��{ON[��ߪ��7�g>z����o"�t����B��3k�.k�b���3)�G޼���V��[�<�M�;H�[�~"�Or��>z��.�#�؅b����^� �G^���x������{��舟�=8�@���%2%p6���׺�u�o�蹞|���Kp#��q�C£�c�/!���H&��y�G����O��D���~��a��A}顲����y�G������]&�+������)[ӥ��w;�_�Q���o����:*�V�6�E�1Rv;�Ӻ��7|�|�~��H#�Q#�N��H���$%�Ƶ��Kq�#�F�et�y:;ZD��Y�n�HlZ�]k"�8$n|�މ?ݩ��r��ۈȏ�E��RW��8N�%?΍�����-�3��VJEBԣ�.G��Y?�.��N�¹�{��}��P�N�k�������;�.8�+��7�ޗ�!�9�Y'����fs��暐���/��7�`�ё�bkg�ڽH��95�C��%��}_�ϸ� �s���x��9z�Ʋ�'���h �o�Si+?��7��ё>�M"�U���������2mZ��� n <�u�X\粅,N�NP /��L�M�&"����hy��F\��uӊx��I��|LZ��f���n ���=���$�Ze��I�Ѭ�?���T:��&[V?���s��2:�qoq �p�y�G�T��#��� J���7|�|�q9G23ˤ�����E^{��[q2o|�߸������]	���z�-ϻX̬�u�.t��%��ȿq�~�kIz��`D�<,WM�b�n�V��ꊼ�'��R@���͠U�L�H�����>�-΍��;q�?v��ݠ�A8�7�T���=<�$�W<�yĮo��g�'�܋vو��qH3�C2��P3��.�Sk��?�/�3�d���;�%y|��N�f������vO}k/�#~��Y����N�K�`��ͯ8$�~�et$��!�z�s,��`9�M��f��b�p���s�2:�<9RB.d�4�y�a$v��Y�8��iş)�@x�?_FG����њN	�(�܄m�Y9���UgHq���H�ft�_�*uDIw�A�����@ST�9Z�3���:���H����q���#�E�?#�PK^��gX��n <����H��|�!2�v���q��(|�N��|�����2:r��}��6��8D�Vp����!\j+NN�³_:V��b]���cO	�Nl���<ҥ	��FW"w���2:��OzGdF��#�K����s��<e�#�8g�2:3/3*ٜ��-i�6�y�Ϟ-��R��t��蹾�2:�?�fk�XM:���7�um
�	�y�x^6>r��/�3s|�tۼ��#?js���v�bly��#��蹾�2:rG���#�}^M�O��r����G��~�et$�lߣ���������ncg-b���G��~�et�n��	qH+�z��3f��Ze�xS6>r����T�����0vx��`ٔ��3���|RW�Vn���2:�G,�s���^�6�K0"!��\��r�GO�2/�#�3�0ct�&��C�dpt�ҋC^�u�q��s����ԓ1!��������FT�}/i=�|�GO���ё>��b-y�D��i�����dd�H��>z��}��;�"	��~��$���̔�_������;|�Q���TM��|�9h�+c    �܂��|�ᣧ~ŗљ�r<��H�e��3�{⁨�;�އś�����/�3�|�R�7-��|�yz8��f
T�܅󆏞�/�#u����\s(��k7Dd��Y��y�#�N��O�Rj-��ш�?����`fk��>R���GϺ1/�#uE/��@�]�!Z��R9M7{
�#�[87>����T�����n��x�y���ӇI��U������ԯ�2:RgFW���s���JubF��Z��΍���/�3��h�n��{C�c�é�����8��w�y*�G���,��/f�:m��o#�6��?b��ѳ����H���Mv$�:�S0%$x�j]�.��w�yl��Ō<NB�w��J5���H����G��_�et�y�J���"�@�̂4�;���|1ۍ� �9^ZFG�p�����T`�vjȊ����>z��~��c	�3�q����8Gqj�v�:�t,�7|�4/�2:5�Ygu��jBJ�Ω7?�J���K7|�F}���L��b�mj���j����|聴ϊ��7��c:<�{��》����Q�2ㆯ���͌���S�Vh��L:/��Y�is�ܭ���~v7|�F�۟�{��D�J����M%aA�*j�������7>�w�O:fğ�%doN��uN�"�pUz��a����މ?�T�I!E�]B="�K�;�E�W{���m|D�ğt*�D�^�E���k2����4�Zc�e��.pn|D�Խ�T�;��>�#�.�x���ubM*n΍�蝺7��U$i�!D�v�'�:_�"�|�����e^FG��������C���=����9���Y��et$��\�E�i��Z�K&;ی��p�#������"��쮦��#R]������a̘Y��>��G��R<U_��Fjt�>
⺀�n�N. ��/����;|O��D���N���r8Cէ��źG`����G|��B.Q	o;x�x~:��*�V=���G�8��2:�w� �zZ~�F49u2�&��^݈������o�et�7]���jF]�`��/���2Ys�+����������W�06����ZC��ב^�ڜW��o|ď:{/�#������H�X<�S���XW3��U���;u>U��؂#�����ܚ��#sW������� �9YFgt�j�d�r��W��,H��g�p����B7��M>śѧ��@\7W�Ʈ�w24k��"��+����S����j���D(�^>dxQ�/k��i�#~�Gx񟾏F<z�8iI��n�Bx�銓醏�t_FG���.�l�nv����m|�>#
�.�7|�F}�O՗<�� I7K�~��&�d��Zpg[|D7|��=,���-?�^�t����v`LdΕӅ�޸�=��bH����SG�1xS������5���%��7�a��=l/%�G�JS���L���ǥ�9ȼ�P�n��8���ɥSv��JQT��)ՙY�T�u �[8o��:ӣN�#Ȋ:-��!)MvR���i9�Ax'95�Ү�ؠ��T�n*J������<.�����|�V�(�#�S4��{Wk(6��K-���p�GOs�/�3��#N���/9ŉ TҸ�9�5�a��8/�2:r��~�ȏ�W�%�<e�06K��'_�:�a�#@x�C�ё<NZ�H0L�>a�N�NnsV�Z<�*+�����љ��`K]砽>O�%q�U9�5���>7>J���S�ŝ�HEնHٲ�.�l��@�H3"���ύ�ң����oƆ�2#?jZgP�(Ĝ�T�y�������Qz�^�N���+%r����W=U�;�:|e��]q]��(=�����K���|B^<�UU^s$���x�Q�=B����{?�w��}ч�>������O�}
r�s��(��w�Sy^n|$>�<W�y�$ƶ8-�=��7>J���c:�
�fZP>Jɫ�~������;���ߗљxIw݅b"u��h�6��A�aP�s��x�Go���T<O)�5'U-!^���:$r5q�������9
g�QJ�ճIV�;|��y��$!�J.`��'�����%��J1IGz��<,3H~L?����󆏞�m^Fg�Pb!zğ�k_�7����on� �$i��'}��ё�e�q�ST?�7=�ә�m� ���!��ѓ�������m�kN�x��?K�b��c��<�@����֕Z�O��$��Ӱ�#
������'˩8�;��Dƥ�KGB|ZK���8��w��Hމ��T�l�����}�L]��YG(,��W<��;��r�X�'E���ɫCL�1��7_�s��;sRrjN��62BM3뚓��d;�D��S�.-�䍏䝺��/&��}D��E���8C*s�P��O˼�ӯ(���O�>Mv���i*g�6��$��䍏��#95ĥ;Q�;u���=W=�T2���gY���<�+����f���LN���D���x��D��x�#y�_QN�+zd��|���������d��R��[�2��3�;��'O��[Pz_z�]+�Śɢ��j9-�7|�F�)��ρ�#2��9JZgȭ�<��!��F����<=꺿���{j-���:Ϫ\Y�\��wѽ���l�>��v��S��F�e�w�|�ŵ�����s��>n�g���P^FG�{i^tq��:�Yp�D�×>��.NN�{��G��|w�;r���u�>��)��O�dA?y�����u���L��s���0U��dpе�_<�dHK��7}@x�c�����#�E@�k��~�(�.<�	܅�3�0�R��6.	��>So�R�9��??��O�LCU�rHZ�V�W��4Cn)�_}�>��LS�r�?u�1�O�&g���5)��^���> <�s]FGp߻�si5L�D2�K���y���U���~��\O�60��#XՅ�[l���ΰ�3(�gތ��
Q�<��:"��ˈ�Q�<����.��,N�K�%3Sй��x)�w��_��7,���3�w�����:J,:rV����G�IlT�P��^�"y�g�i�9Q=Y�z�ջ���V��8����> <��]FG�ɾ�lC7�u絛�11S>�\s��>��Lލ�#���)�ir���:�9[��G�> <�q�љ{���h��ڻ�M�I�YZ�ϥG͛>��%Ϛ����C������|C������>��w�d9'{m�O��kp:|�U�E�VKsU�"����3 �>����\��RE�ASB<��!�t��&;N�9��M���7/�3zBd�0��U=+ՍA������>V]q�g���C��zH�Wͫ���9R3��ˡ���_�!�>����C�'�!���π�H:����Y���> �ʩ��N���{׽-�1���KJT(U��M�A!����@��~���
�2;�%2�Z�U����������%����/ͥ�֓��H�r������s|�ёs��[�)��u^ۃ<��I�3��ӦϠ��et�>.�USfT]D�����]�>�Je���G
�1N����wr���v��{-����E�m-/?�6}@x�������5d��\R�e�5ء�ӘVZ��-������s����æ���!���b�+W��[�P|RM�*�g>R��Csp��פ[�<�~]�y�f(�FD��a���G���t�C:R������v,	Յ����x���|��u����xn��\�}g.��T<§�#U�3����� ��y�'^�܋��>Ղ�nIō��k���3)�Ǿ���L���*͡s=9X����'7�<�־���3��~��ёx�Y��W�o�@�q�6,�,nh��6}zG7���f�\Cѭ��;�/Nd�ʯ�*~�����Ҧ�@���^FGp"�����ǅ�L��+4��>7}���{?4��'�L����y�b2��ۏ8�x�ͭ�s�g ��<�et���!�8Ll]�����3,z��B2/�7|�^FgpZ��Jk���T�MTR��-�7|�<�p��N�ehlվ �+���Ɩ�Ю���^���    3�;z�tL�� ���3i��m�&Zn6���3�6}zG����Q[������zkZ����U�x�A��6>zG����Q���p� ����Xzu�(�c�_~i�w���uI�rZ���o�*�I�U����s�g ��9����{2uF`�׊������I������3�󾳗ё�{%bNf�����f<rw�W��ңN�>�Bx���PW�4Ȃ�)����ƔV'u\�&Ҧ�@��Q�1=��+5G|�zߡWG��~�ҵ�n����y/����{�͜tJF�=k���K�JL�8}Y�2i�g��l/�#�{m�V��gݷ+��1}��H���󆏞��5"���:7�Uo-��tbvK-]�LӦ�@��Q�1=j�N�b9���p�8G���H飵��7|�F<�����I��EGU�eEt'�
���X8o���y9�Vב����ni?�~9�:}�u�æM����y�c:�C�S#uD�7�7LA��t�\�ϴp�����1��XsWaJ�X�4D�����M��_��ވ��<O�V����5|��� tH���f}��>��_G���$h_�
?�_Ҋ-�'k�ʮ��z��;�N���[�#Q��Πsg���H��%��¹�����2:�'��PU8t��ꕡ�hjb"A�y�O�>�Bx�#:5�C"�l���_FT�7G?`K�m�s�K�>��,!%�L���+���p�AR�}�L�>�w�p*��U�~��֗�@j��oưyPiv�u���3 �s��etF��Y�I����~m�
Gľ���u/��3(��sN����VU�����>����trߗK�6m�?��M��L8�ڒ�3x(R3;f�a��M����.�3�s"1B<O�%շ��֩r���"��7}�o�]FG�ݵ��æKP=+� Xp��yxv��M��q�0u�p���kuT[/���vT���¹�Q|C��2:5�ם���.�ς��mk�40�=צ� o��x�/��j�t���z,5���Q��ܺ��� �<.�+GH��Ӕ2U$������z�M\��+���~'զ���-�:����9r5��m|��8�`���i*u��Fz
�k��Z�\��� �s=�љ��Q�(��i���>�h�M�'�m\y�Ϡ�9��Z-!�����'�)\ɤ2qi����l�
ṮO�ñ;�t2MU/ӕW�E�!1v*\��o�?��l��3�*:o��[y���ctrӯ����3�F�~�C�(H1T?Y���6LY�* �<_z�i�g �����H�[Oˈ��u�C�Zbн�s��f^��M�!�:Q�ё��\��m_�=���AJC�$�دy���3(�G�t�Yj�^�Q������E�}��I3�|�/N�>�Bx��^F��w�*��+�G,�/!I�&pf�
\8?� <�K�ё�sݑp��C�X���h����U_���;��P����Y��צ�� ��v\b�����M�!�����[�l*d�|W�O0}u�#_gTy�t=��|�y�et�7��R�T��J��Mkf��*H�/���H!<�/�3�\��Q��t_y5�j1�I��`��?�6}��ț�ѩ��aK5n�սW�π��iN@u�x�g��N=��R��ڮ���ߥ
�
��y\87>�o�/�3�\JҖ��~�
�8*��KbI�(΍���~����9�;��U�a��w��T�kh-��!�>CHo�s]FGpNԄ�( �AWA�%�)�8������wqy�Q>� �йr�K�ɴP#�}�q��M�!�7�/�#u��x3c��7��D␆��V��.���(��_���q��f0_�ꥳ�Ę�Gge�h�u��3�w����:�k�Ӥ�I��D�����'��� Ӧ��鯋����H*��޾�^�B7��2B,ݷ�m����x��n�q��n=
�D�3^����b��Ҧ��鯋���*}D���K8�*&�pt�6�ZS�p~�#���]Fg�Lmx��;��WԽ�߭�E�t���c�g�����c�u� (*`��t?�h��CW�0<߬��לi���;�u�X��=I-`�0tcЖtU�l����<?�Q|��.��ٮ��pT=���HWD*�sv�z�n���</s�c�� ����#��B=�MY������K�>�Bx�Mwl^&�UwK)���m0�'�;r;��M�!��_��שdUU��nu���*]�DD�D�å��6}��N]<�_��2$�{��x���#0"�	�T(_�u�>C|��.믛^'�)��W�E�`��=K���{�M�!��_���e�t�~�#���G�&��	��j;m��ύ����et$�+���EUCrN&�ϵ�`gq�t�Ҧ�ߩ3�cu�L�SNo���Ug��R��r��-~�� !<��et$��و�x�&���	~���>\����G����X���%:�/5ի�{���ћ�X|�ͯs��3 ³��et�"���/�y͋u�8K�&�A�����6}���d<��3���GԆΝe��A:/-͞x,����3���>�et��XE�@� jM��a$3k#W������3 ³��et�y�B@d�귩V�}z�ܮ��ƾ^��� �}����%��G*
��U��(Uo���~�g�}��{�_Fg�,#��Ud���ȋu,%8�w��Ѻ����pAx�>_FG��v+:��}R�/!?*��9���O����2:�<�Od���qH@��=�9"����p�?/�>>GUQe�s9�����(\��yq"�r4~���*  ��a*�Wi���b?Cp�7_FG��Ptuu3^WM �{��'�����{�O��Ӽ������QXcѼxj�'Hi$kq�ٜ]8��G���w
�pV��e�Ɔ�.8Vm�N~��|�g�q�D<�qS��z#A���N;����3�@x��<�4��G�舯��jr���}���4�����~g�9��޾��/�Ϊ��B%��c�|=��|��8eX�f^�V���v.���hs�����G
��^FG��PA��/]��5�5��E;��??�v�<�C^FG����m�w��l��z(׋��~�#�z�Ͽ���C���,��u��{p|ץ���s��S*��C=�et�;�:�?��K�W�7�g�͗�2���Y����Xx������>��>5�U�*�~ED��ҐL	�q�[8���s���Q;B#�*�|1Α�%:�ρ�-�O�6����������֜�I�/�޽�A�jfv����Ծt����	�=onFG�5V��wͿW�q�R�cRϹp�����ёs$����B�g�/@Fѱә���gN��p�mFG��<��!DNC繲��#�ӤE��� ^8��{?���C)������U?D�cH��}��_�3���'oFG�g*T$UӨj�$�?U�ZE�{�P���7�y��6L�q���H�O�ٿrХ(�f��&���_}�� ����)��:�h̠�l$'��V���n|�ʏ6�#��LΎ��Qo5yh��V�Ku5�u��>7>�_ş�ёz2w�]�
�#^*C�A�)]p����x�st���BĹAj���S�}��τ���H�u��}�g����Js��(͠{le�✶+SDlji��?�}'oFG�Q��5О^�<�2�@�GАq&���_}���s��~��&�1k��мX�����lW�o��:�ft��l]¯�K�{�L� �jS�NR���Ϳ��?Ax���)��4p�t?B�ک��H�����󆏾��mFg��cG���u����yz�yk�p�p������ё�;�"�{�TG�12�̬�G���L��7|�E��ft$^��pԁ�З���>*a���a�]8o��}��ё�^�Mڗ�{�}��Ε�ز�T�Jq��w����ݪ���-p����"��PswY���%���K���H}��YL�_���{o���2g�/��G_��lF����#��#�tb'���N�紮ȿ��?Ax���T��>�FƳ�������
����o��G�U�    �ft�I�g�ي�Y�^늺O�8�[ڪ'�>�O�������H������M��gsy{/5TL��x�#�j�|3:�_W�v�N3׽�Ao�M��)' ��s�#���n3:��U�������P��A�Zr�+=��o|�?�9G�P=L٨iK�����k֛�u6nTg��w������ی�|�{�Ѵ��'�$\�bz�	r��>�|3�Ax���*�j)8m�sD�d�TD�X)>�q���}�g���G���OA�����;<�Ts���t�G_��nFGx�8��q�]���M飛Rf���c�	�>�O��%:U_B~A�u�'�.���jEۀ]va֕�>z��D����n39�w���1�89�J��z�7|�F}�N՗f@������/%���ѭϕR#�3�p����%:U_���ݒ7$Q������XvB����t�m}_�q���-��G~4�Εk_z�vP�l�"W^��F+� ��c_�et�7c���u*ΆxI�^w�d"�u���' Os|/�3�}D�"���s���y\&�?����O ��7/�3s�=!rO&9�)���"?j-Ԛ���X}�s��Bx����Խ����;�P��9MA�d&|Ul��үs��O@!<�+���ğ�Fӭ2�:<^珲�㍕e����tq������et�?�t��g���T���k̽��eݿ��}*���os��OΓ+���%R {"?J�T�a�V���}�P���љ9.�r�L�7��aso�¡�>+���ӱ>�ޓ����Z6�+�O;b��������(�n��.�#8��;���qZW�%���}�m����Q��ΰ�;ƴ�!@�]u� ��}��7��2�֞e���y�ё�M*C8��]�v+"��J�,�i��<�����u��.\�.5����9��b���t�G[:��7>����/�#q�����U�L�t�����"Ys���7>����/�3�q�7���N�?�vX��M+�ܽn;[�2�7>���q/�3s=�n����~X	�����%����G�q>�et���ls�5rf�/%��eOݕڑu��������ё8�y��L�j�A���5�}����>��3�S�|���y4���g[�x����J^8o�蹏�2:��du����]$�wt��E�������>z�{�2:����i"N��X��uTM�%:`a�Y���u�^F��*7��C(x�249$��DEشpn|�o��^Fg�.�-TΑ��I]7O I*H?gj�ξ��6>�w�>�w����9��Y��;UV�u�8�\��t�q������H\G.�֐�I�hT�Sƥ:2#��KgO>�f/O��2:�_�g&88ղ��*N��H�S훶��O������et��_MF7��a¬x�B�0r��������������Ѧ��H�MBX��R�sz�y�ʋ����2:r��y�x��Z�ՕՑLk�J����3"�t�/����L]�"H��M=L�W,�};�Iq��'���;��:mC�ٺ����T�U��?�:{4]��I7{Ax��y��K�\H��Q������I�<2�B�]|�I7�����y��K�VUۍ�(�&x�J֬E|*��3�@x��<U�l�&N�X�����"�o�i��'
��>z���ё����{#���P<�:��ԩX�k������{����9b<B���y�9�����#���8�s��?ꐿ����B�sr78��)�� �4T|��q��n|��8;������V�a�z���L9�u���g��S���Wqy����wdm^��i�3H���q:��\i�_��y��89W8Pa�+���,�d�~�۬{FTW�������pn|��8i�ù6m�]Hƣ�*b���1|V]�p7>�Y�3�Dk�vz�{�fվ5+�Cv���t�$n|ďu��ё�M�L
n�} �,1O�X>R��΍�~��3�m�ܵɛ
ܠ'�o)�'.��$N*É�i�Uݘ�Ԩ�`M�m�#��t��;>�A��!�5������T�`�GE�kWo��x��+B�YgQ.]�p��R(��E_G͋��.��舟O�%�����9¡�2Z��M?����G�����i�n���N��X�!	�*�|��Z
o|�u�^FGp�3��ث�!	yqMV���L���<7>J�ğ�T�j�9�f����U'�`�dm��5c���(�S�I�� }H�]S��U'����v&�<\����z��w�6�Tݦ��eo���L��i
�3`� �������G�~O���\��x	,�{ĐtV]nJ�e"ǋa�w��G鱏�et�y�t{�����^u5����S�]7$T��ay���G�et$�)�j��9��n бSFB�G�>��,N7��l����!i]�+=��d(�UIw�9G�tt�&@�T�Suȭ��y[;|3���G�'�et��ej3�0c��w�<��Ƶ�F�9\87>�Y�����\T���e�oX�)�;���.}ZI�,N���<ࣾķ�)*��c�9]�Q���gq:��RH��к��k�܈x�\Y�3m|$��6/�#~`rH�t�U��Ң���[���i㣟�ɩ�	gnF�+^rK:��CE����m����~'δ�Y�Iݪ��'#����\��uϕ6>�Y�)���d3��*��W�Ks4�3��#�pn|��8���"��6� �*>[8��>�����{?�}r@�Qqp��]ͪW�Cct�i��Ǹ������s�!���
���"�UA^�+~�����->�;>�A���,��i�����2��{.��_�p����l�J): u�6)K�a]v�TĮ��.w|���3s�O�.)Ī�fe�X��ptu�O���I^�H0�Q��0��L������"w|�ʩ:��:}��=6�9�az$7K}\}�r�G?�s4n��?T�G���u�#�u�v_u�ᣧ�ϗ�}�޲�3����q�uSl�#D�,�~��>�I�c�C�&�;Г���l\�9Y���u��=��IH,�|t:���F��sz*����g�ᣟ�Y|(D�b��S���3"�p���$Ϊ����<���+B�F���4� /�7|��_�2:/i�� ��k.�8�מ���nu�¹���N���ş w|��L��N��w*���9H��|�����,��+,�[P�(8Q]5dJ�bs�#ڕ����4N���pDY����<��!�rG!��"o���г�SzV���%�s���^'����$�t�P.K?$�̿�?���>]qHо5�����!�,��^s�7��_�nFG�b-�#0���	.��Z[k���A���_�i7�#���MY9�'�2�ϵ�t�d�p�̿��������y�����QὋ\���]�1r3���>�����CjC~��`�U�2�im�o*aƥ{ 7��o�DۇRg������>�xn�#����.7��_��ی����YU���s��m@���5]n�p�̿1��7���:'E��!4�_����"�9�u�n���;�g<�}�)%������;<�W�'��#:)K?Dn��]b:�K,	|H�\�u|�p�	���f��o|�щ
����!�˺��E����!����l�c&�wt�©�����B��?c6E7.�)�w+�]zV������D�L��U��4�T��7������^��y�/�&6�3:Q�YW�ͬs����1�mC�H��z�y���NT8��b�Ӕ���]�Է��'���C��z��wt�±����-������-��^Y\�m�K)o|��3݌��Q��t�?E��m��g�9C��CJE�M9�R�g���ё���sx�����:����SΡ��9N����}����@�*)ܘ��LAo��Ԓ�Dq�?�y��E��ft���*��<���N�ۙ��8���� ����;[+/�@�����$q��=Xܤ1���n <�����M!�4�tNj	�����7@n_uO=p����ё���ވ���q���h��T��!ԯ�{�zV/�3�Y#U�ת|�ë���5�Ƒz�:    p���Cyq�ߡ�"U�=PՑ	�fHW�q��&�3����_FG�y�Ґ��~�:ğE��U���$Y8��;��|�	�������Y���ͦY�lG־_��/�a7�#�i����Uuj�=��|/�0r��>z�%~�����u�TvU�X�!?��q$�͜y�ᣧ<�et&�/�;],2SU���ރ�!ike�A�*��Ax�ҷ	c6[���׽�K'J�z�tb���X~�6>
_�i7�3��RZ��p.�yd�����u[\�w��G�����݃9}XB��F�P��o���7d�΍���>��љ�5�:�AVu_AA&�{�B�΅����G�{���H���x3��#�و��p�t��Q�΍���ߌ����73Tr+��og1�'ǌ﵇�~��I��etfn��V!?�s�Q�i�A���̓�/������3]���^��#q]!{7-����U,��Vwy�>���7�>*k����`t�^f�
H��#N�IW
�}\d�C.y3pf{�����`t�y&
59zѾ_V��d��B���V��8�?/N�w��{�y��MD���Q��\����@�����ё8��J�[���sqoRɗJ�J�����������>y���؞��z_\��I����KY\U�W���8]�ZM(F��:����<���%r���?Cp��	|0:r�cG�1�̵���&7Ȃ�^/�����/�Cqע�\���|��M�%�\PZ8�����O�D���z�§KQ2�g)Ѥ֨S���N���>��#~�t���#�G�8��|���Ǫ=ac����gq�����E͡y#�c��.�^�gw���O�w�a��^[�bĪ��4����ErZ�;�s㣟�YPx4��2"Ѣq]E��/�8��w��Q�~����ON� �����y�a���\C�4��w�,�'KϪf�{�}q&K����4P>��Kn���N��3�!���[b���v헡i1MokZ~��S>b����~0:◢��;�c�:m���6�Q��ѻ ���;��0������}�d��_{Ī�V�{�Tbg�!�����H=�!^��L\}�$S����i�}���|������?��h�������G�(���2r���/���ܷ�9G!�`#)�j��J��C!�5hu��/봛ё�Yݬ2�[����!�L��K̺�c�%�>C���0:�<���H�!^�Q7��l(P����M�~������#qrw�h�Eu�a轌4c�$|��N�!|������'�b�eݷ+�V�x�椋���}�·z�����8=6�R�Y�=�Ӗjӯ����|�^���љ�]��9�:/��e��Wo���_��3���w���ԗ2��)�x���Noh��z��u�?�Bx����L|ZIݫ�@��i���j�eL��yn|�_�	lFGx���9>���?�����|kb�x���G��_�S~��I6<Q�Fe��־��$nT�;"�U_�{?�Ӗ�IKK�i�<T7Fi4����!t�΍�~g��C͏ԃ�Ŕ��py�L��U���~��+���k}I���g�\��V�Yo΍�t�>ɋu0�����#S�X��}�^zpK��㽌��9���o��~4:4�.�S�A�g����|�)r+��p/�B�v�G�#y��P"��U���g�5y�=���y��w������Vt�'�xջ S�Ȇm�����Q�A~���sy��IN�eՅ��{��è\����V���7�K���%�~m�#�D�;�|Po�>4���O��v��G�3:��;���,!iF�z���S���ׅ�r4/����ёs���*��YTn]-#���߸�]qHp;�/�ɛ����u�S��M�ɭ�K��N���|��7���ht����D'  ͋u�D.�U?$�RZ{�r�ߝ�Fg�m���X�0i5�fS�j�Fs�g�y�;����>��6�iw@Ծ���f�JqS�e��o |�'���H?m�m�<��6�T-����.ő�u���7}A��3.����ᤤ�!�t�RR97W,��w�q����l��`2N�T��j;~�b��u\yG����C�%ryf݊`�v���?�b=#�[qH�7��>�z$GsM�צ�_�.l��F�����w��K��X@��i����q��t��#�}2O��y�7|�]��G�#��n�d�Ӑ��Xu��51J�HEb]z9n|$���~4:��GLx�H�S��s��C��9�Rk��{��H���?�>�Ⱥ���Ug��ߑ��J�֓�1\87>�_四љ�:<��������A���	��6��E��Kq�����Fg򸬓=�4������X�fh͙�����~����{w��[����{�yF��������pn|���|��p�������������j��\u+k�n�����wJ��s}4:s���M#����#��U�d����Q��˖c�A㺗ё:X*�����yN�7�6�ev���Ck�������lFg�뢋팛�|�ED��7iJ���:�·}����@�1Y�
i�.\ՍM@L��65�����@��?������9�K�W?-�^��;u���W��t�9�Fg��gM���4�ˁ��Al�F�����}?_���H�1ڈ�uN?�=,NT��xSg�N|��;����0:s_�X1��A�`��ҧ58���k�~��|ỹ�Fg��uр�Q�����.��b���1W^�i��m���3���Pz�U}Zm�jR<k�A��>�³_�Sz�.������о�ͦ���Z"	d����³_�S�q��ت�I�����[�uġ"�t_s�������Q���
��T7f����ip�"�̋���Gs����΂����<�G<J���S�RB����s������~4:�?S�N�p�k��3�.!֎`~,]�6>����7�3}k�MQAo�9}�)D8�$g���/�>��~3:����o��ޭ*hk{����3�u��n�����Fg괤����Ryğ:ϕ���.v�K醏�؇��{�����̕E��w4C�����y��ѷzV���A�6u�XԖ��}�%�Yf�X����(���wu��Fg���K�b���<��<h���f\��醏����`t��0�4���+��3wwa�Ă�Cq��w��P���j�i��+����Ѷ�9�Pk\�>�V'�ё�O�0��+�hn��9��WE��w�>��l3:��sm�z���脸�;<���D6�ʏ䆏��/�`tFw�J��|�Q�Mx])DƭƵ6J������A'�ё�3���x�ZԹ��X�M��z�����G�����FG��w�J��! E��V<�6�eW���[}���у���#u�������V'��'��$3b��{����~���P�AA��r����W�|4	O�T	.�>��(|��j3:�6�>�Fo����~SIIם��+��;�Q8�9����at�'0Z���zEw6�P���_�YmFG�ρ y&o�J�#Nֽ�֚�Kw��(��7>�r��ft$A�����qu1 -]=#�Cp�-/?�7>�r��ft$N��QD[��� �T}�t	����=o|��/ތ�豌X�����&p��.�IN7W���˖���Ľ[�$9�,�Gq& @oJ==�?�k&�hD�����ΝY��ŒK��e�!�8���s߄%�f%��g�*��T�.�q���G?���Vg`9����X璔�4�̦���?���&t$~�5jv1d�}g�(p4�܊ ��+o�7��+_ЛБ�;��$���r�m�~(�c㷙c����s|Bg���46G�H��kfg؀q�iv����"o��W~�7�3����:W��0�<QUE8~�i�O��;~�u�мv�e�Z�-y�S�ǵT�VI��������M��y�ڭHPf�����Z�|UZ��e\ۺ�����2�T]PQ1O�{��xGf�I�̋s�fk���/u�pl~�hgU��+�2��@�⠝��=w�݇?
    ���p
�; �I�1���R9wfU@Q΍Pد=?�Q��S�&t&O�8T6����*���PC���<�����w��7�#�Sf�i���Ԉ@���K��qK�,=?�Q��k�&t$?��C��)+~gi3�,����R�����/��p��Q��ܤ)Mr8.��]��to�� ������},�BG���5!��Qz�o���t���*��z��
�|�C<��ΖбNŉ�y�<T��@��u����_�|8��]�V3.�0�>g��xs4�M�����G�?>�֏^BG쒙	0q!�#�R+SE��ة�~��>U��˼����j��I��¹���г�6w�Ɇ���w���Z���cfqI� H��R0��e�M�w��%�R*�mqq��ϕ�#�rݖ�4��ճn��2y�Y��5�7�R��j�)���!!.n,���+^d2T8؉��Go��3mT��u/�#��t�]��R?�0o�K����_z�W��G�����t]��2bkkY�p�3��^�����ѣ��d���L��E��P��wdͿ�g�Eܰ$ �܄�'�q�X��d���v㏞�3��SÅ�u�]B�"���,6�斝�;t��^BG�!P��UX{38	�S�m ���s��3��c�8�f�?O	�CХ5]�]�;���4\����$�N��jCdGm�A_��G��r�q"�����W�pHj�D�%\g^z��уz�Q�&��t��AO��
^��@ʗ]������K��y֐k�Y�QV�X���0�ͦ������уz�^gtD�v�O����~oSp�p�۫��y��\4Au�>���w�*):x������������%.�^d�	�)L��aJҶ��������-!���&8O��`�l]����!n�~���q����u�]"_�	�{B#`��W�ޑ����,�9#q��5�{/�����q�M\����уz6�$XJ8����
��=�[l6������C^Bg�t�.5%l��1�+f�\E�S�q�ϝ?zPϙGk�����[���b�wYyo��G��]����2�cp\i�fh��]��s�Գv]9���ϐs�31�4n�nIF=�^������8���k��DI
�(�Cik��;tS7|	ѓ͓.9�y�x�䦲��L���ޑ�����jC�@�x0܋O_��vWؚ��/��w��A=a!C��������>}�d2�h/��?z�<���,��|��*Dx!#�K��Y8���уz6��+ HQJ#N�I2\�6�-i�a����G7}�/�3�&�' �yN|��:sO�3�J�N�;���͇�8�]"�	+��ke���83MXu��G�	$l<����2����pQ�e���k�1/=w��A=�)��T��4"�^e���Z!�"�z��
��ݚ �y���O�N�0�ȕ�;����!4����2�P���a�޹V�;
;tS�|	�3�,n4e��bߚ�y Q������;���RW~s���Ww$�	�� ���;����ڴ��R�F���fE�b�w��G�I���T0��AR���F�9;b�}ᐰ�GO�Y�N]{eY��-p>�U��mN72�c��t7�:���4��:�+O�T���z�8]�kϲ�����IG��$y�o˸8�X���g���0��X6��7&��=M��x�p��Ž
ϝ��9�U'���$E�j��Cg�W�*����'�ġ�*z�f$�Ye�g���~�-��՟=7��I=m�l���?��{�q0�7?s_�(n��]��K�^�cHpz&&Aa?�R֚�G������=�'М�ؗ��Ź�:pHI����u�����#���o�_BG�g�&"V��Ʈ�c�+xN���+_����<�}k/�#�}�أM0D��2�SţQ��l-u��|�p7��:3���$"$��v�)��|�bL��n���a�p�g�:r��I�,mV�|2��MCX7����|�~�K��z�K�]�6c/Y�2�g����<���1LH+ޔ�
���C����m:�w�;prfHHM�^$�Y20���lT���^BG�u�J7�X�y��?�Q�u	������
w��%tfAj���+[|���^I�9�5����~�K�_��)>�d[���V��f�*��$�wP�0�_z��
���Cs�#5�=�'�{gߚ�`�+��w%ٕ��n��_Bg�4:v)�b�;�G��Go�����������Й�{� od��'��*ų	4:��i���l��?�K�^r��LO<��*-y���\������;~����Yb-d{�[��s��*�%�Fiś��Gws(/�#v)#4�6�s�X��u6�� !Y�jS������G�C�P_�(�Q�n8��� k�������y�o��^BG�Q�\͆�����㼶x\��������>�Q��{	9��gϔE�<�WuN�����������G�v^�%t�o��a�"�+
�հ���*��`����y��Б�O]K��)#�]�a�0N�9�sޔ!+�>����W�C�NΈ�F���/�TJ�T�g2�p�zG������!t���L���+_�}��7-#Q���Ӈ?�_�i߅���*���k�nI�3T��8˔�o�z^B'��d"��k�Q����0*���pr��G�v��%t�<uw���»�1 �*RUIW7ؔݺ�y�½ߌ����V�TA>��O���(�v�{Kύ?��Gx	��Rk����,	�Q�g�6s�b��Gw�u/�3|V9�y��Nn.�^T�V��[���7����:r?�6q��}(��_J4��v1Y[�a-=7��.��:�����.��b	�*��(��K�>���G�\�͡;/d�Co�k�W=C��eM����m�ԻС9��f�M���K�q�9'��������P>�N�
.$7�P>۠�?k�2��|���o{ޅ��3@�`V����$��(��̫O5o���f<���"�M�R^X��H��{l��V����F�T��o�=�.��^O�~�̼wh�_��c�-=7��x3㣖���"-��&��[��\.|�K�$�ěr*��$�6�uS���y�'�EE���Ks˿���xSNśA|6��*Ρ�>TҶ����b@�$�ěr*ތn½#Ԝ6�np� �1S
 _�5Xz~���{�ޅ��� �$/Y�%�4��3�Q��i�w��䖏�%tD�$�L�c�z"����5A�$I���Hn��^Bg���<����>��d@ȣ#�71]]z~�#��gx	��J@��%*"�"]��Ew�������?
���?�潿���O?�z~�v�����m�:�,\g�F�;��Б��T��&ɷ^����+9D�ty�i>U���^Bg�e��0�r�U�fFȉMv��M�9}��R��~j���qU(���T�J����pwݜ+oc��3\*�����I����K����=s�Θ�X�!�?�R�.>z	9O[��e_�QlZ%o�
.dל)�.�����R�&o�:3�a��g�+j�w�K�t� ������F���:�����Qӑר��j��`���N���p�pc�_Bg�v�ʔ�g]�C����f�+��\�=}�pW�{	�����>+�U<�K.�Ͻǥ����<����3�]�*N��N�jq����37QO�S��t��Y;D��p�2����UOņP����u�����{����kN��>+Y�L/w�D<��<?�Q��y~	�;�͚}z������$<��f���a�w���y�^BG�g��1��i?9��8ۜ��D_�����[��Й�H�X���s����E������x���G��p/�3y0i�f��p�Lv�� u���q�y~������Б�M(9p�e�+��p�e <�Ă����G��p/�C|�s(aK��������Hz���?
�}�/�#�8��|�v��&,��S�`���g�����-��K�L�b���zf}Sp������w���:���v*���/�3z�i��wpO��4mB��.�p#    ��s���*_Bg�g�\ĥZ��R�%%3�
G_㕯stW?z	�����lX�:;��DxΤ6d�9h�6�讯�%t/q�q�h&�w܀��ڹ���ݭ��6��n^�%t�O�M`��ڏ�i?�AG�3�\C�޻������K��\���M��.�ƽ�l�k5xWu��z�tW?z	���z7��{�C�0���^��P8d���1n���G/�3v���(�c=Ε�jb���y���7n���G/�#�{����2�&��p���'����������Տ^BG�8�ά���Iqba?cB(�u�%.��w*���+�놤�T4��!ګ�Cn�n�4������=8/�3�y�A�&���/�����^tYs����K|O�G2Mv^Y?+>y�p���hMf��O��(��c��0=������O]�2��Q���W>����K|O�G��S
jV�r��8�W�i��\��6����=8/�#x��^a�'���jMZ��W<$�\����G�:B<UG���W�k�����W#�%�^����%t�~�b�B�߬���~N<0��xc���G�}�/�#�h���$�ʜ�!��:�3�{��G�v_�K�����XU����m��;l(U�q�ϰS��~�~�t��-�ݘ���P��\p���?��~t����dj�+��q.'s��tQ#0�q�����G?�G���ʐ�J�D!�o��-�l���[^�=l��]�K��y�0BQ%K¾�C;짃��W�6���ѱ��f�����8�s�aF����L��!l����x�~��me���]��ޑ�~j����/������G�T�H|1l�W���Y;��vḬ�Q�o��?��~OՏ��)�U�k�*�&ן��
�.����7���Q<U?J�H*���x�ik��`<�����a����G�X�(W�]{��qq�y�?Y�¸<֯�w*��ՏPQg�=�H=����u�1�UW?X��G�K�HNՏ��IzG���X��",���:zry��?�
��h	��u-� ?-��+�,'Y؁���2��A�{�������F��̇ "�~��RUX9��$�sR/�3<<z6�P����*�*d�R���Cn�?�_�Gr�~�q�y������@�ە��CEl篾����C�:b�/���㼡�X���:�Z�U7��Qp?��K��{�up�	B�����,3�]HV�F/k/���U���Б�n���}A��4�j��" {e�<C�돨­?����w?b�`��ԝ|�!�ށX�����G�S��~�S��5#0A�a�˱�;#\�u��چ����?�
w��/�#v~J�Pɭ�W�T���z-P���o�_D~����GL	�����.�E�`9�g'���3��]��#�p��/�#�K���ja+��:����}�hL��y��GT��y(o�sonp�X����������Nw���A�;~��Бwd����q$ҳS${(gG��H�������6�Б�Ҋ�]��OnAUc�Ɖ:r3|M��t7��:S�-�Vl^�ʹ�0�;c�m H^8D6��n~�%t��'�u�_��[��� �w���Zo�yn�������53����j�uH4��CB��㯾ʴS��y(���+�O�*�"xRY�������_�It_�������)�o-q_y�Ir#W��)�e?�����/�3���ɷƺ�c�8ěvf��u�Kύ?��;{	�38==�Xq�G�5�~��ɴ�G�>����S��H�C��}��N���~�VLM=ε'Ԥ����X~>"��ƓɅ�rq�%�++����I�藹�plnb��8v�q�Gk<�����+5i����?�|k/�3���C T*��!�g���D�\D{��Ӈ?�e�#�度��*�8�"Uz*Si�iF��������K�H�g]L����X�O�v�Q�r��l���Q�>?��w4ę��Pn͝9���Pڷ��#�_�f��G����K����u 5|q�a�<I/η�k]���Ꮰ�/vɟ�K��1���8��S���~�l�p�]���Ꮰ�/�ӟ���h�k7�;@�5�JZ��!����_zn��}!�C�}t'��䚞��5��f�bZ�I_����G�}V�����{��q�,qsy�M��}F��W�7����:���4�Cy�]WC��8�T�u?7�����%���
:�L�{B�F�i]+��×��7��nN�%t&��^����7D0�=�
�
Nt�X���>��/�2�ؼLA��u�*w@�k^{��8�Á)�	BO�w*���p*��溟d/+��w .�E�J�X��3b��?
?�;.�#�.���_w�ro\Ter}d@��4��շf��?�e^&�����6����2\��d�o6�K���� �?�Q���:�{�gY��*�$;��i�iδd͊;���G�~�K���Ɲ(*ͽ�xI����&}�����G�O�%t�[oS��c?mѸ�>�8gwF�?����7�%t��Nϻ��޹�/�fbo�T)1.=?�Q��{	����ٹ���`ِ��*��g�������G��˄s�2	�`Su[��Њ��0��eq3��.m�����9�8� $��"+�w_'k�~�^q�E�~�x�_BG�4,s�؄�|��u��8��$���Kύ?�!.��b3�Q��o�}|x[jd\�<���s��y����")sp����~�>Z�a�.������K��<�m�㤶ᾞ�|]�C��\���s�~�7ñx�[K]c��'-~	�E�iw�����~�3��C�:���ĩu���:N"!��&8[�V��|�G���(����&t���=��Y�W�	�{�JZ�6�^t���U��M���YI����D��I�m�_�/=ӧ
_��ބ���.�z@%G;�aIk�Q�4���V/���p�p�g�&t�<kf��Gإ�`%�~��[�_��nT�Z�z:S����Ɔ�F�To�PC� x������B��~�S�3�2�N����4,�A�)CLj=�/=���`�����7�#v��Y�z����Ж���]�i��w~�K��ο	9��z*"����;jХ�X��~m���p�p�?�&t�7F-ƨ��}�}�U�^m1E%-����p����	�	�!��hf�礂�߳�qr�����T��{˛Й<��L�35d��XU$��o.e��!V>U��{�&t�~6���RS�ֆ��Ϫ�q^�I�l��LU0��!oBGp�A���T,�s���u���W��z����
7��7�#�!���2�t�Kg^1p_�R�ٹ��2�}���Ӿ	�#dkz#����<<(ן�Ƚ�,��KO�W��|ݛБz\�'ŗW�P��J�L���B��\z��GP�ο����?��Mp�:�)eN�� <?zI��Pמ;���#{�'�&t�<_��Jw�O"�d�T=�>�1�/�5���#{3��&t�/�gC"��|'�-y�b	j�+����#{3�&tf^���\��З�����/
Xi�1�^8�}����O�M��w�SKHy-R�B�. #?�D�\Y��}��������YǁȲ�.�p��V9G�(0�?B��ч?���!oBg�gҍ�����id��	�����=K��yG��;
Q\������8�M[<�ƒ�����7�_���]BG������ޘ��]U�8�;�����Z����7�#z��"y9�����2�7K�Ս2b\����G�&t$�878��p٧�2T�5;�0�����U���Й~�`K� �#����a���k/�����y�����x0��=�!#$�;⸘�nyJI���?��{��M��{�2񵳒T=��w1Ic�+���R��������#�	�K���|Wu8��� *�Z��9�ܻ�짗�
7��%t��J�&I��iVnJ�1n��.���]=#�5�/�{��S�]	G��)���}�w��%�����x?�)�(���l6�UxLO�b1�p��z�ҕ!m��l�[y�`�]=MJ@ɝ+Wa��!�E�l�7=�    ��x���T�k�͛�=3&��1|aҎ{pt�i��1I�+����^7|:�O�FSW��p��p�O��j�O�����y=o��K�L��!p��yE�V��x��b �pC�u��
V�+:��������}�)Ϗ���'� ��U0�q�K舝o��8�A��7�.������׹�7�#�]�1#^��}�:�wX ��[3��i�8.��?"���~�7�#�(��*�E�sd"�єu�s!k���W����7�3u�b5y�K�Tb�/��Q����pr�P��{:r�9�V����Ŗ�͘ftvf��엞�S��}VoBg�G0�G��*:�a&�0���U��K�nT�yG/�#�Qn.>�D��U�y�b�@�#]~3�O��˼	��5I��I%M&��4N��b����D����	��f/?�t-/�N��{5��bsm+�F���:�L	�{��%�'�*L�r�5��A���g�T�+��Й��F	�3
�,f �N�|�>�}��yʧ
?��c}�����i+���`5~�EOzUY�66~��>�7�3�6S8�Sȯ��{�%m�)&||�����n�i߄��Gc�}Ѕ)�������Y� �_���lT��W�&t�<^���م�;��2!�P/��`f)�?D>��MݛБ��&b���˰Ε<i%����W��|�� ������Ԓ��bU��~��%*8L��][sgV��	S\_y�ބ����d���X������D_�8�U����	���v���G�qG�*�����/=�F���:b�k�zQ�� .���N
ϫ��lc�%�n⸗С���Ib���L�=Q��f#S�^�ȧ
w��%t�?D���Yȫi�l"�Dn.���麟i��y	������֨L��r&?�`7fj�gYx^�
w�!/�3��!�����p�Hw*��`�(-�s���{کp��_Bg�]�DI���(�\
&!������T�+?ÛЙ��5���j{G�:������)���
w}k/�#�����������o�T�m����y�m҇?��	78�%t$RB����ށ�U�Â�M@,w��Ӈ?�ٷ�&t/9�l\}����e8y ��O�,\�>��ݛ���Ȕ[�b�8��_��S�"�5�������/vIN�%`%�
y��"��p�!f�r�9�K�$�q�K��y��\���M8x�� X�ޣ�����Hn�^BG�稭WZMϦ0A|T��m��ވ-��L�H�Ͽ�	��2�"�hG���{��j>'�`��\y��]��K�L�k�]�)���&����ݦ����^��(��U�����\.�qkG���l)��i���o�t���:�	�C �8#�zpH�������W�&����7�M��;��W`�
y�-�E���9
~,�����t��:3�k]����m���[�r�����k��i���*	��q�Б�٢784e�e��������洍SHK��W��������cv5�U�ʀ��x�m�nE�6�9�w~�������	�u)e����_�e2�8v��EdH`���w~�����~�	��!�G��'�˴�����j1y��KϼQ�]z:37�R����%�w�}����C�k?���7<�&t$�4]+Yu�}���� ��4�����T��\ϛ���a���l
C�Lb�7��v;���nT�ǽ	��R먃�\�s=���9�wت�G��إ��T�k?ÛЙ��)�FN�����iE�2<���N׵WȽ�3�T�ڷ�&t��.�=��ߙ���Q��xe���nx�ބ�Թ����"W�{]8wFR��xf������M茝wE��9p�&M�O�U�A�G/�z�����M����R�r��{7���t^��kmV�����?z:�����VQ���P�UE�� ����.j���n�Pބ���R+��T֏}n@N#�s�	��z�3v>�Ӿ	��Ɉ�J��T�C�x굷���O�	f�.;o>���zV�U�[�wkO=���R;nL[z�UxLOm�rB�Q;�Q'��0Sg�'���xG���s)s~3�<M����:��@��t��~>��lU�Zu�c6ioH�c�eԵǙ����y����l!�I�B7UaECk�'ߗ����wT�u! pI�t��[5tDv.6�����G���O��C&����T�9��5���y~�χ�'[�GJ�69�3]r�3��s���>�����Թ��<Q�dL>b�^��K�^/�iw*�Ǜ�T��t���`�1��8�<���Iko��;�����]�~T]�y���g���Kv���S�BS�X�E"��8@� Ŕ���{G��n� �ȾJ��=s�em�]�ky�w�{G�	�3�g�β�
�uy�HJ�k���^z�<��*F�e繬�X�A��Z�)З�;�����<���!pH*�8N��<�,=w����t���$.';�B_�K͔,�ƥ��=��d��kI�z��FU�g0:11�~0gwx��w�X�Im��X\wX%�̡�_z���'����'[���R޼�W��e�n�Y���)5�4�,तP��.=�e;�F�ǭ]��~�b	�f��?Ч������ѹ����� 8U�lS�y�m������{ORɦ�~�d���ʄ�|�A����쏠X1������!4��Xj��K����_�G%���*a��eSa ����v��/��4��	OH��s7��2�~��jͭ�+�v��>?�O�/e�枻<���@�Y��x�&��b_���G��F�ӲO�8��T@�
�4�N�I4�8��{�Sp;�U0�]j�P	Ʃ�M��u?��=���)������e�Y����t�y�y.�w��A=�X�E�
��7�J�L6�)�_�����.�� <B�����{P�%@�j]}�q~��3�,x0]Y�ɿ���ʥ�͵`��ۥ��=��5���I��:Vk�g�nR�̟Kϝ?z�~�Q�
��>hvTs�<"�K=�+�w��A=M*�v����=5�J		މl�Kϝ?�ַ�&t��A�Ṡܯ-R��c�%��P�^��.��уzf;�h��)x�ٹ�GW�}�V�����\����_�M����Qj�]�8����c��^�v*��7󩾵<�v����g�Y��Һ�0��Y��������Ӿ	���ö́�<��������)�R��x�O�����}:�?_��B��Y߬�G�����s�����d{'�䌆uw�l�6��<��=�>��������ܰ���&t��:�0
�qd�����焤�9������wz~���	����gPִr�	d������WO���\/��U�	��#?�����흅��k�L�_�æ�|�g/��z���A*|�|5]�`��^����Q;=��s���j&�M嵋�}�;�_ޑ?�p7������b���{3�9��?���7��&t$�r�_[8��I�UH�R�������;^�7�D8�`�{︟��T�Դ.3�X}�)l�ғz�$=ON�����-�Q,
!\�`�V�|z���
��ћБ�,��R���Z��;���q���M������U���߄����F��IJ]9���W�3f%��\z���7��&t�?�!��@I2�7��qh�YG���Li��cz�Sr��p�޻Ѫr���#�|��e=���Y�_q��*�#����K���*|�;ބ��%<h��m�՟��<��]�,���.띝�w�	�'wO�*DC�?��Һ�!0!��[{[�ޝ�z� 8v�s�zV$�OJ�%���2���Wރ7�S�u#���c?C2UU��D�Db�ѯ}�m���y�7�3���|{ yx��#�&bΒ4Tֶ,=7��+ơ�����r1�Kqǐ������~�Փ3�Q>4���p�Q�ZJU�u?wx���Б�`�5�w��>������ݮ��vz�b��"..⠝u��.p6r����Ʌ�Crܽ�_��!�B N��-�    4���8���g �f�ڻ������:�g5j	\Lo� ���{��R͏��:G\�KYvv�A=�]t\V��Dq%/)��� ����O�2�K߯�.�>L�>�?��}��&t�.S���U!Z��p�&J�`|o�����'^r��߄��Vm&�fv�O��ܠ��-�.d���Jv���W�|��	�ѳx;đ���|�@�6�8 ��ե�lT���^BG���bҪ��Y�Oʺ02Hn�'��L�*|�=x:��h�D��H/� ��6:L������\*�ॗБ�!�3�6R"�$�H2p���gf�e��~��/��oL�S�hKrF��~N�Mi9_���~��4�׉��s�7�'<�"�Y}qW�|�~$i�q5') �t�7Ǣ,h�>�U?��
���g��P��^Lr���W�D;���9)ٝ�u���	2��܏ ��9�f�:��?]�չ��󱽁ӊ�����u��=�����9-\���y�|j�Ю9)(֭e�y ��ʦ p�G�+�t�|��}ă/�[L�����RH��m�v3^u�M��W��7�#�(�x�Ss��Y%͎ӝ��*kψ��s=Y7��0�M	K��qCF�|\K�D����ꛛ����M���\����:���Cݬ�ϱꛛ��׽�oBG��	������J�jG���hĮ������s���G�$���f�w�M5��������;�s��S���3Bf�bgS�:��v�r�^�w��`]w�" ��L�(��j<z���L��nՏvy��2�G�	�nlX{��?G{;�鮙�꛲��>���VK���>�ŷ��(�B�W�(���O��W�Z�"�V����֓���\}�w������y�c�k�K����T03q�3�ŗ��.�yǽ����Dw_����T9*�I�>cc����-�]>�����N��ꋇg �$N��9Bx�r_y��>�g��{aCr%�k\��V�j�XF��C����{K3Ep��>h?��#g�Nk�T���a�W|0�\DKԶ�������k�{7�甡W}3ǝ
�+��L�p�j��7�Ϯڴ��>�(y�?�������8Uq�C�MW��Ԥ!�p����w��7�3��V;���x^��2Ǎ��n��a�:B���`�����9����+��w�؍�-�2W~���J�_�u��y�cLn�,�c�^���M�3�ي^y�?��R��.�����u
�R��w�ik�Jʴô8�헞n��/��C},�E6�y���/�#>��ö�|����*�����=��.
Г/H���c8/-��9_=�F�_����o)��
�p���ĸ�*v��> �_zn�w~�%t&���*�0�'^�ߜN�P��UG؃�禎pW/~	����\̅qR�?ϸ#Ee����u���}�p��_B��u�ӑO@��ү֡Gt7Ҫ#�M��o����	��Fw�%G~0�G�q�t>�G ~�>T���%tƿ�޴�*�{7<�4Kf��I�s��3|���}�oBg�7e��}R.���g�
X��h
�����GP���/�3�	+	�ι	˽�q��A��tח�(|���&t$�U;[`��ym3U5�s���E��W}3|���sБ��i�X\MkY/����̵'4W�un����ѿR���Ӱ��}�?b��l�	�}�;�N�'�|��un5ԫn��	d�s u!̋�,���e�����M~w��M</%sNʏ5�����l��g��O�K��ʄ�0�^����~�?;�e�֥���f^ =��Ʃ��M��->������M�\F�����BO��
6��l�^!�ɫ�l�αDh'_X?�~Ӳ	T��}�v����.B3C�%ȱ^l����.8��J���v<<�ֹ �� ߯d�w�`��/<z�e�����&O��ܙ.��=F5=I�R��GԾ�V������&�����=�a��-��ՉQ}��څ�ʚ��{ӳU;,�w���.i(�k�J�����������Pj�.��U\䯌7S�߬����j��L�zǃu���e�QN�Q��|T��5�H�?Y�����������¹	����ֺ����?o���������>�����]�&�1�i_���ߣ�ޱt+lM��A������d��q��s���`~����l@�����(J7���u�����\���ݓ˜*n	߽��1��&U˽BI��䝞���D�63/r�P񢊎Q5`O�{jݯ�b�����}:R�?�e�!��7�9�͡�,6k���������M��w-�܅{[��)U�#�F��m�\z~���w��7�#ył���ʬRFH��D�On-/=?�u�{��&t�<���Y�U�t��� y[���ӆ�|]�o�	���2�]@ L�_ ���X��$���{ǝ
���C�Q Pn��)X�������q "/=7����ћ�=�Hej�Z"`,lQ�F�v:n�-mՏ�&_�5�x:�HfS�����E�9X�v G�ƴ����~������D(7�����f����(q�<S�K�M�������n�t&�Z@�N�D�Mo*i����Ǎ?���^BGp�t!wN�:���̈�0Y��)�p�zG��<B85� �#^�����ߑ��D.�8�yG�u�����r�pjs�7���/E�WG,Kύ?r���%tfV{��  ��_\�ǡs#�'Y�����#w_?ZBGޑK�u �(k?���i�@��)�u��Q�랦7�#q܀����c��T��Z����l���tק�:�>�w�㘭�,+wcխ��v��%�"/~����$���W ���y	*�i�k�U;�������N�Cp]bV�,v��EU�Y��6��u.�$t���:�7k��(���6��5z(xDƷr��G?�]�Sy6(�LV0�K��B�J�������x Î���:W����Ǳ���.�Y\q!�.�߰�|Pώ��{F��SoU���u�s�?wՏ����z\sA�Z��<�e?X�<���v��U�����s|�EY��ط��K��Dt�ͦU��wP�����55����O�;S�]]�#�v�G�7��b��n�5����ۮ�qn��~�]}��9���
�uX�4$�ĕ���>�ï:�n?ף����Ϝ�0k���M7��?mx_m�] 8��>Y?��-Ш(�@�KJ�q%�֔ E��SM�~�'�zsj *�{�J�n���]��w�����dj�$�p��)��s�0���g�vy�'�$��F�?��afV�O'�Pm���\�9�珚+d�x=x>�������1��I�:O����"줮������:��
�����ޯ���~�g��[�:�2;p�y$"��Ul�T�u{���;>�'�\1��gE�*�-Saf9��}����?ʻ��䤾��(�;�g@��uXgf����yl^F���\�L�M�q���K��k��߾���e���lk� �w��}������ֹr�����+q]/���w��7�ǵWH��]!�/��s�\�1�躐�&#Rrc��4�T~u���&_�C_z8u?��!sO=�VG�q�6gS�Pc[����ׅ_���=L�d�Yu�&�K�	?��2�vW�f��������d�gj ƫ�œ�I9�����c�ϴSᗼ�)ޭ0�����K!q�EU��9tgV~)}���/}��T_:�^{M�f�p]iU���1a��p�����
�y�%t��������\�����`T���F����G�*���Й~�'G&L�;g�ΛFX�g�����N�:�p��_BGp��lUZ���ι]c�C�0m�xJ�,}����;ZBGꛣ:�0H�:��YISej�`�,=?�Q��>��gEpM%�?����R5��������KH<�z�>Y��.��~������)^����_�C����i�9�K�y��� �݈e�������?�����	����5Veg$_z�>>q�u����vީ��{?���k&����v<Sfgm8)1T;����?��W|:�_�:K_�    A/>�������8��k�'o��},�X�М��u�%Uz�V��YD�%��o��},�T>h���s�k��}�\�j�d�����eބ��%k+����@���]�`JO�xD�4{}��?���%��c�m�����V.2Bf���Z<��8�:ύ?���w{j��u֢p��^��(S����"|��~���`�(��!%� �+789V�;[�G�i�;��z܃�#�"��:�d�,\7�I]�R\�;���>�؜!�}���
 <&h�D4�������<X�h���a��S�ݤ�^�1�Tx�5��|pN�p�öLB����9h7U���U9V]f��u�>\��u$7"Yi-�)G�Gos.�yow����#��H��x����s��P��]|�i7��~�Kw��i�n�Dn�i��w��$%�a����_���-XQ��_T1����և<R�����ʃu�B������'TGN*,�#�]{�vu��G}�dF���>��K'}�m��1�U?ڝ�{����"�LMG�/潻B.n̞��b��=9�Eĉ�d��s_���Gz>�h�*�_�����#��!����~o��L\R�J͝[1֞д��$��'���3�6aro 4y��M8���g��{�Ε�4@M�	�+�lE�\F�ǃ_�\;��d��͡�>s'�w�Sg�����u����gO�,Y~�d�({��p�*�|�^`}w��s=Z�KxI�2�\y�����9��HY��]��z�c�W�-� 4s��y�2L��k�o��s|8��mY���k��|�p�Y����g����p"HO�s��/���N�o{��ي�7���&⩹	��`��f�S��W��fBl�6;�Y������!�����}���d�K:^~��4�ڦjV\=7�O�K~��'w�a���xc2p���ۺ)�/%�w*��_:�Gݵ.Iմ�*���bUsU���#�[zn�?웈��MH�#{µ�k3G�3�d�[S�i�s|�s�����^Bg�\ә<���Y��x�?���9h������������A��]&밬tf�'�8 �����������|��Ѭ�$�K��qq$Im��*�������s���U=m�RS�r��T�!��g5�v��M��.>z	���5�D�i#��@�����f�F��/=7��.�x	���a��8�H�^�����%g@zn�n��G?�w�Sq�cWjF��:,?~-ک��ѳv���?�a�#��;��Q.�%�+r�2W���9.i�����T��o��l�lx,����)��'��2li~�dz�?}A�?&����m^BG��8���̑U�.�\J�lڐ�^z�
7v�%t�.�K�������2{�=�L���۴S�ƿ�����f�)�B���#�wX<�fB�і�f�]z	�K=W�R�X�q���g5��u��ԥ�ݨpS/~	�/9v6��� � �d8?m��V��(����?:'�F�R���r���28�C�}�է��~�`���4<y�F����1�5x�d:4]u�]���L�q6��!�{1��5�=��"�����ͦn�d]f��ZLI���~6Vd���q����2��уu�9a/o���&�{�Eo#\����~���r���x����<��*���z��k�-�z�.��d]�`7f��Y�Q״�d<���ڼ�G����2-pSq������w�D�e$�[Ը�s��{�.㌯S��>���;��<��v��O�e����&�&�~�$�Hj����wȮ��`]F��[$��]�����.o"���g/����u��������[K�)�fp�ˈ'��;v��O�M�\�=�Bϖ�
�0c�Քu��iߋ!�J�w�9��%nh����]e7ˊ�6y��&�:Bv��ZMn���(����T3�+>�f����?��#� M�ěEs�LR��V�ږ��<�|��T!�$�y0�q��V�<>���������<�s��;�YjfCn��܏�J�{��ErJ�����_�&��;*�����f�F���S�dZ���=?�`������7ɑ���/�O �19!��tM��{��<��27!��&`#��HVE�w��>��r�z~��䗹	977!p�k� qr��B��$��%�KϏ<��27!��&jJ���Dn[��QE�T*�.58��QO�Q�y95��qR�"4������Y@'e�3 vpq���?��<�K�L���Fe>�V�]mU�8�4W����a?���2� �� ��n���0N�VD�9W>sa�@�+�m?���«)��`���p�J����e��+�y�|�fYq���G����ʇ��CƩh%3��V0����RS��s�~�G�S���N�ؤ/\G�|��:B'W��Gv㏾���	ɇX�ϑ�:l�~C�U��+2��������gt�td��H��x[Kc�ػ���s�~�G�c|�>��Z�� �M���V��G�a�_�h�~�Քc��:��-=ΰ>��=���Gt����2n��/��PȰ��5�y��P���'n0�nx�����x5�T,Gfv�;��0E��L{�K�On}w��G?�j�)^M��a
j6֋m���R2t�5�e������)�x5E�QB8<|�i���8�O��`���ǹ�?��?D���HlF�P��v.�^����wcڊ�����"��Ct�M;<��U>,��^5Ú����s�~��S�!8�m������f/�t2�"<rڶ�o��]>�%t�ߦk��f^�}M�eU}6�6�������y��K�8�8�oSl�jX�(nF W=n÷�h=��
��L�f4�R`?C�^g|��q��;{p��F�Ŏ�lp�=1o�DB�V��ų'��|PO#���2��!��&5�h6��c2�p3o�(`�qr��sr�!e��ebNd��[\z��4=8g��M��x�m	��0�.c��CY��]ޝ�z�Ɂ]�xo�wՍ�?y�ns1��5�����侳�%f�
�e�!`��yӔV�xw�֋+�\�4���k{��Gk�cs������y>X/.5�j��|�C�b1j�b'�>��7|�O֋G���;bH�u��6�+�C�0���U�r���u�i8��<Y~��u����M��-QJ[������e@�f(f��!���� \���<V}3����a���5����t��و��1��֭��$;���Ys�&����X������k>n����|\B�>��J�&ov`]&���S|�$��"��~>8���͡ID|djI�fMS�a]����N���C�`(p�.4�f	#��ϖ̀�4�n������ڰ�= �+�g� M��贷��U�|G��%qpI�Y��W�m7�!9WO���>�ѳz���࠮��~o���<cM�g���??�ѳ}	���ʹ�<�R�Y�a��:ڪW��m�?원S~SL�C� � ω«2��I�0E����}���aAN�������� ϗ"lUG�P\�O�S���y��Z����d�� �$a�� "0Y+��7���䘝G��ej���e$��N�jBq Sk�.���?�G�S��&oa�K'�|b8/G*�I�~�M��y95����^�y�*yJ;�g����2�7K�M�3���Ù�c9C����s,!h������u$٭���t�v�q�KxfTF#��G���:�����M�>���q]�����7.��sA��\P�����+{�������>b���sA��\�df�pD��Rȗ$p�"�����{=����1�O�!��jfm}.���і�U�M��������򝹠�T�t�[�H�����_�U��<�������#�;|��)>U�x���fR+ƌT�#x��sѫ���Ʉ��K���%�2}�ő��G���}r\q��?�#����~�;�#�iD��a!�䐉���/�BD��)�&|����G�QW_}�
Jg>�~�����'[���콞��G{e�ۜ��C����Rn^*�qm��A^�Y�kKµw�?<��	_���C�̭�<�����z=�    z�q*�2;�����˄;�q�+n�RN%�*�/"\<긱����䙷��`�����l�I�q�~�d(H�J��[>�'%�7�#�N�$��s_��z1��jK�V��J'~���&\�
L�@� R�g0����k�u��E����Wh�b�Y1q�L�z7m���'u�{���^uXJw(�O�9��!�ʁ��ǵ/�	Gx�h�ҙ�i�����H�K�R[}���^�&�1"
�:	Q�����+ܔ���w˺8E��z����sLVLrnmy#S�~LW\�{(�����;�������<O�G�K���椱��w�N{=/����[�C�[����g�FRU�8G�.s�?zs��$�(��ɥCJV�fVn!قL��H���\�/�܈�������X�@��p���xG:|���ǵ��ɕ�s"�l�,�{+d�_�ߧ�c>@��$w���<��oC�cr��eN��E;��f�r�0-��8�	�I	�����˜�_�eRB�w.��gg}D�͘uhZu^�p�ĳ�"oaýH�P�Q�H1M���ڕ���y�N�S��yy��#�X�>���ajR�#u��,���KǶ�������V�Z���3�<�$c[DFZƈ�Ʒzҽz��0XGD��dl�;oj� �L�d�/r�Go���#!x|�$7��4m)�b;jL���]8׉�E�/�̀�=M⛳�)�E'
#��W����S�	߿���3}0qP��*S)5�,i�]T%��s��џ�w���S�\+�ae��P�͏L���<y�,R[�=G-���w�����)k��T�{K<_@�FXֆ2f>�}.����5�y�9�>��,Y*#�J����\�ګ��-��|g�+?��UQ:̔�nU�V����aCu����G�;_��C�������b�<�F�˷9�0ֽ)���}�����r����%ŉb�r޻y�H:P���O{������O�*��%��K�K�[S�{���ѕ�}��	�q����$�
+�鑬!��U�(�I�F��H���}�����!$�7x��7,���\)���|:��o�I=���H�2�v[$�P�R�Ό>������e�!�ؓʏ��0HE�_�wo3�?����v��}O�x���w��}݇<zF6G;-M�Ĺ4"�g�x?m:ģ�\�1^#O��،�H�:�G�ر���KNw�L�xtc�+?��5tU||H�{ 9ﻃ��#��2l�7L�xtc�+?�υ�㰬���R�%�0����g���y�G7���S�\A�5�H&T�[*�7J��$y��t�G7���S�\xɾ��J_�'¹i#�'��TU��S&����O�s�j_a��U�GH���u��36qnl}m�y�G7���S}E�+}�ӽ�>Hm����e��X��P�i��E�ȹ�[U��A����%��.�k��/�&~ƚy�n���Sy-\�" ��x �	Gxq_F��s�-o�rt"���Eё"�Q���9�\/ډ΅�T>8��F*�X��<�m���S��M�+1Qnڭ�BJ8���Tp�6-��O8׋��̽�j�8�d�Dٻ�De�bؼ�z�[�7z��p��6;S)n�*	�;|g�%�U�8��ܗ�Q{�v��ȣ���\1����o�yO�ы�"��h
Gi/^��/U��.#$�'u�Cy�A��-u[�>,u���煃-��8B>�w��wLS&�'>痐,�~F�����U�I���~2N�����~9�%�u��8�����S���ί�Md�_Ss��a��r���w���zy!똃<{m����k�J�M���Ujm���џ��mk���6�S����mVwI}�:�)�T�3�l����b��`P��"�i���>Í����_
>��f0>�$#Mk��vI����v�7�&�c�q-ے�˨-��4%3U+r��Q�=_����������.p�k���1�K�N���6�#Y�o;���6?=�ޛLT?��/���gC}��mYH\��<�|���<�H}4��"x�}�8��	�-]�@B;�Ʉ;s��4����'ʚ�Ã�$�O���Z���~�y�������3yH�-�l1܃n�{��8��9������;�-O�y虹�PjR}�8��J;�ˠ<����m�a�:ܹ����=۸L���āW�P+��Ѯ��r��w�{x��Зw8��ϼ_��ä�UFM����������C��9UD:����(s�֙��qtA��<�Q�/�<�L�A��4�w�x�2I���,�N�,�|�/��������;.��G�w\#��2iZ���_�^��̅hW��v�O��?=�М@k�ڵ�!_*��p�L���o;���;����LՒ������ɛ����6�D���k'.NЂ�^�_�� s�:�x�v������_=�?uy]1�ț=��!�烧���U�K���L����g�?݌~�{�G%g�5!�e���m�L�[<���#､F�����*��X��,�cd|/��w�/�$9
Nkz /%1r ���p��{T&��?��g�����~��q(���?zMm���'�����������G��!�*�.�/U�8W7��k�@�~\�/݁b���\c��O�o"��c�\�,7�9o;��yȯ����Rں�b�^OF�����;�T�ߧ;ģ��Z�z���J�K`b}�,��Ϙp������7����d!IC5��g/$�#mj�������֓
'��o~��C��%*pq.�2�G�tG|_#�\Fh>���x^�ӻ��r_#��T�i���FWuQ�v��[�?���ͱ4-N\���|Ե\��*���Q��b:��v"P����!���<�ύ-{�"��ɹ���믺տz���*��R�iF���C
��`�����ڷ���#s�|��Х�;#�u�5m^�$'>���ɿzd�WQ�jh&tn�����{�kj�I�]N|�o�Y}i��LMda�;Cz�")�G���#	���ʓݚ�1�+ܗ�~��L����sZ�x���v����z�\�U��o�M�7�K��6tR��v��v��=�H]�F��3
��>O��wfUP#iJ����C޴3���{-��Ó*ҧ����kY�w9������#}�բ�ȹt˹JܨZi����z��}/��|�N�:s�$ro��&3u#���d}�y�K��?�ʯ��G�O[<'�dP��[�!R�Ak	T�O{o�����ޮ�(C:����>�,�7��+Z?4ݼ�ٝ��^܇u�٦1�����_�����c�9��CNs/·x��7&r��Gĵ�*ӌ���$\{��я��C���U��|�L2�XE<�c�VV;.;���n�5�����K�����Ơ6�&'���i�E>Ո�h��/ԇ�7j_����4kԽ]N&���RK)�
�쩏й��ԃ9!�϶�L����S��Q�'���6��Z���A�K�}���қ��yv�Hº��������\�->��O��/�IX=����䜀�l�$3�oK2�|�{�'���i��BV���>��b7+�@����=�N��/�/��ղ�$�dw��f��nuV���|���|��է!��x�@h��F5���a���/�d��KV�O;�k�f��ᕧ9�־�6����^�ۍ�!�ܣ��Q�&��'A|����}����6<�/�2��j��)r�}�e�GI�-�x���^��K?=�}ΥN<��D�}"2�YP&� ր
9�k��c~)|͗~z���fӕ{=5S�{�Tǰ���ϥ�K�k����#��x��uՉ�"�ˑ��ӺU�4�=�����5_�y���1}���ҤD���Z�G�l�{�.�L�>������t6���$.S�dZ3�e�I����5��y�?�z�u��p�!
��+^��+v�]����1���u?=3���0nV�N\{=0�dgC\�Z�~�'d������3{�q4���y��_���K��5�����?=�}�J�
�Ƶ��s޸�c�UK�~t�{���p[�Qi�q�=>��ble]��mb<���.�]]{�SKG��q�t�����O��ȇ    �inJy]�kL��m��&�/�(�?
���ř�W)�U��M��J����	w����r���G�p*$r�>w*�Rn����v����ٛ8r��Y3��}��������/��a<�i�:���G���r�#�+���Bɑ�-�k�|�wK�?Əq],�P[vr����fd
��U�m�:|�oڙ$��5�N!椸�s�!�8C�n�����"΅��dMd�%�+��2Z5ߧ��K}��-�s���Y�m5�Ǚ���	�]Y�{�0��s��y�hg��d���lL�Qw���GQ���y�7qC�G���DNO�g����0ʾ��-r�(�i��M;���7ޑ�9��+�ג#W�$�'���{��կ��ӆ���R�!̫�])"gu���X��&'�ȿ��z��,�H�dFKܛ��ϔe,�MTqrnxx�o�YVG������"��_�|E}�B�=J�t�w����ݚ���7���k�K��z�b^���u-�?�w��Cu��@C��!����-=�wN��.o֟��E;qQ�29�ýHR�x�!(I��<����7qXNHG�s�$���G.�mƨ��S!e����87�gⰃ�ި7[�y�e[����͟|��}���I��p�b�IEn�[���2sX�/�x�7_�acS7y ���ٺR�AH4����7O:�o�Ej���2��q��ӄ2y��@��7�?�q/�z_��i�Y�C�l�=��ˢ��7n�����XVC\�B�<�;��g�ߪ����ͧ��7�[�=x�>W�p���|3'X��y��?uF������#q�H��
�b���P'ʘv�����H����<��<Xu�6k�έ�[k�c��Rl�y��o:b?=7��6�l|�^�E�ސ�%�|������6L��#�3~�������qD�N=�ft�:DP_<f����+����#�g�޲�ԧpv���kr��ύ~�kÄ;8�<4��u�F�`��I��^��MJ�0�=���_�������}���<�u�E�l�{�:��upO����_���C��L�.����p���kﶫ�K7�s_;~��z$�O+��`.��-Qw:�R_-�s㰟���~��C�����)n�;!ε�T\n�r�х��n��s_;~Տ�y�~��H��A"��/�?�q�%���\�;&|����G�2��IM�}���ZX� o4����|ģ�U��硇�;JI����+�M]՛���<��ɛ���[�������$k][L�hOB�lg�=�ݟ���k=����"%q����\)s)������Γ�ԋ8�m1p���J�h�?����URi�o�O�q/���.}Q�����X|I��G�7~$�~țx���Q�7��v�|��|)8*\��s���/�\V��kG���geQՁ��br�����������ޙ����XJ��5��w#H�r��t�m�	�{q�L��
�sup�	 W�+�D��q��y�h'�O�P�K�����������[��LbO��~�S|�֭�s2v��L�����i&�q����w�7|�N$�AXK�{o�P8�9�GEx�,7�g��5|s�K�29��Q`b+ȓ9$3�)l<�g�"��&�!qx䍩�	e�\W~�>t�)��~��?���4&mq��sOj-��sC�'y�v���E;9��B���y�w��f��=�&��3�Lx7\�{��/MN�pɸ�'Ou��U*���ϐ�k�!�[pI�P����]�*�u��˼��Ӿ��{��[�HA�����^Ou݄�5��{3��3����=�9�wȣ[�ལ��58��I���C<zs/2��J�N=
7�w�i�F}[������o��7�M��e7���ǂJ����@�Ș�ޛH������ZI����HI}	�s��m���|q�TB���&y�|�="����i��מ�?�M|��q��'ˮ��#n��q�t��f��{�\-N�"��o��d���v8�a��o}���&���J)Y��%R�-)����sv�o�t2����5$7v=�?rHF2����1�Ko�s��]~o��B��Q7����Jv���<���}��I�<�_��zP)����kȎ��_��;�Z��g:|Iڵ�8G=�f;�غ$|��ƋO|�/��e�~_��\!�kb�!9"�Eb���~�ǅ��|��f�*�ds��%�"}���,Ғ^{��<�/��S���L��_��R;�P.��7�������#}6:�����9�P$$Ϲ�2���*�!L�����>sȣP8�%h1�!#	IU$��{(ΞL�����KE��9��!��w�o�#A�T��v~���?����$W�.�B�,�~q2��%�~m|��n�M���gpCE��e��k0U
��qI/s�����}���=Sor���gV�����є���Ϸ�<���tWz���S:�7��򘉩�:�2p������<���n螩�Z�}�=�|�Q�FE$#A�E�|�t��?��+��"�B�7L�I��.�Hy��������G�Ό�9��p������%m��m�	�y?J5d�Π�tܓBݑ񧥒�XD�r����^ď��P�u�Ū�?B25�q���e���齿�s�E3Dԛ��i�����P�u���7<����wf�7��[v�c���W��4m��V���}�7q�V4����*�;e&:(籗���ͷ�	�y?�e�;4H;�?��!n��@��ڳF��{�̞��^�e��ؤႋ��!yJ[��](�6rH{_Ɲ����L�(3-��.$\�fe����5����'�t�^ݏ[�.�{?�}��� 5��@" 7������<��D�4�s"+�%*R��h��ϟ����?��G�{�n!��/��(>M�ULw�I�}�'^�7��U��H�J'��]�J�jF��q�W����&�fgh!$�j��������7����u�=)9��&'���jt�?9�,A�(�R
��ƵOs,o�qC5�B��ɷ6�i�:��+j��e\{|����8ܔ����K�:�0̈́P�Mx{?�y��	/�ǑCb�8�����<unW���ݶ�w��s�j��e�0��J�^Ԩ����n���N��E\�O$qc��.�}m�i��[���eN{gw��O��;{��;��#B=���Yv�Mq�6��;�s���� k%��?�}������3�9��|j���>��/-�d7x��!ui���Օ���'�ٻ<��K.�B�� �ڙr]d+db�x�i��E�#vYn�h�顴�A<�(H���('~�7y K���+�U���I��D����*��%Ʒ��q\�D5K|��׎ݔ"�)�7-{~���	�ٹHfE������?����>w�3,���A��U^�kR��="����C�ƏS�m�=�^N<�o�j֎��&O1�2��=��WV�ER��o�w�/=���8�S!�u�r����W֍��龿����"T�O���D��Fk!a�f��?�	��qI�j�^Ͱi���/u���]����'/���c���6�}E��ԭ{�fiy襳�q����t[�#w$��Wl=��#<u���{=��^�{h~	�$�4�_��=u�/�����f����^�����ɓ�m�p �;�)מ���XjF���<�����K�"�3#1n�1�nj�H�D7��4/;x���ú�x̂����D�!���9@�KB�ר���������f��p�r�G��LG�d��Ŏ�n�\���7����n
���9�(�[����[~D?z�{Rr�?zS�	W�M��AV��伢Y�rN��v>�x��;BJ��t�\PV��8�$�5A����i?�E;Cw�����C]�q����n�c�s�	�}����Z�=�
e���r�[���W>_zg�`��p�#8R�*o��D��x �%���?:�2/�G��\<\R��a��,$-	%�]s��WN�p/�+&���Gl���B>?VRm���~���M�+8Wc!.38W�]��03������:����e\vÖ��D���)��Χ����^�G'\�����d#�Ƶ��Cs�pm�^�G�q�	�i�U;m�I��sb�"�-!���,    1�^zg��|s��|/z�"5գ���\�3D�}�tڛxGnL��≿S�����1��]���HNq���#����-qC�[օJia%���~^�����P;��m�Υ�dr�UH鴅����I/�U\�q򂼯����|�$7$���8�m���|�A6�b�~�{��[DPX\���Ҿ�f����<_��u*tI�z|#��Ŀ@Y��1g����4w�&~��9�fĒ��D�KpF��h��~��?��v:��g���"��0X��ó��O~�=���ś<�.!� c2����uu\O��
���CP۝��C�(�CE鎛N�R�*���gۺ���{�&:�22w����=W5��$�)��>�x�;���ӑC��7�ģ��S�����e;�I�ɯ��Xk���z��o�X�/�n��8�o�~��9H���Po�3H+�M�q�x�?��w�]H5z��x���M��שV�ǂ/����/�2J(���3VK��{ER�P6�R�M]��'��qd�\��I�wJ�7��'*����s��go�?�g��s�.� a	�{�T p���(��e�a���ٛ��]Ȕhq{���\3��';��{�k���a���ٛ��3� ͦ"GF��"(�Q;yj�l;���ބ��q���WT�/QR��-�{���;�\�?ķ�J�����E\��XK]˥�,�;�<�G�G���#�����G��;upJ3�
mk���}���=��>¶��ĩ�H%�\�#_�J��ޓr��}�_=���1j��o�#�p��Oֳw�8;��_���zf�?��j$_%����F�ȅ�Uq�ߧ?�p��?ԧ��1�nZ��t���f '�N{�������<�H���H�Q"�D�C���`²ݍ�{�>�i��E�K\q[7p��X��<}�FbNu��}�x�Nv��'%pB]�a�S�q�J��Y[�}�1w>O�-oډ�MxZ��Cvf�K��f���Q��T�ֲ��T �+~U��]���ܸ�ل��D���Ն��QvZ����C��/[�8���^Źق�ʃ��D��`'.�r��K��'�"��tVש�e#�R��se�M��k�E7����uo�\e�RDt�3��r�Yq�2���Z��>׉��E�ɑy��줨�8�F�Z*u�?�['��W��&)���%P�.�6�}⫍� j���;;�/ډo~�[c{�
�X��fM[\v�n�#�7|�<�NO�b�@ֽ�E9Ɏ�g����p2��}�<���
4�Tg0��_m]v�x靝�7��f�Ȕ�̗r��������:ü�<��/ډB2�j&��ܖ�(f�I�P���}������·���mb3�O�.1p�ї�Pu�@����{gi�,��9���f�@һ������g:}�o��u�S�^��CY����d�H{�WN�6��+�ҫ��)ν�0P�!	dN�t�}���&�^��j�Q��⢜c��$;b�^|�<��O�&ε�͂m��Cx�'���RW(l�.�&�ޤ� ��D-?�w4�U�q��C�;�2w����7��C3��8F|��m�e�Gٶm�i��E�+Ք�jT���Z@��ws1w�#m��|�Cy�ʭ���^��=�0��$��8�2��~)�ao�M����5-��XF�dV]�ŊR>���e+�����V�V�H��眪R��J���2��콳��ޙ�u,�I�tR{��=�>�w�m��;�G/�\>Ç7gMm�����cy�|�������٧�|w�Cz��$����o>rO���-�6��W<�G�;~=�H��{�VͲ�W��u�H�����=;��_�_=�?�=�eP��(���([f(hΞ�W��~��|��C�-Q�e1q�MC�d\mY�ԅ����?��\寇�����?3)���8�9,Pr%%��6���������G@���,�G��soٌ.(�j�n���?�G�򐟇��1��O3���z�E/��f�H���?���������*�9ԛ\8a����t"U����#����K?=r�y�G����:��J�(�3��y�2�d�\�)���}(�!)K���Ž#�%$+���k�~�-_�y����X��f���Γ��~墽ָ�#�y�G�x�z�<��Kuf��1�5�Lo�(½n�x�ۼ�ص��Ž	$w	$���d{�9���whWR�����s�5�o3�1��7_z<�C޴��9�Tן����4v��˲!���s��xsOjhrT06=d�Ϗ��H��Qs�6sڼ�z�7|��:�Q�-���A[�MNN��RY��<�_Ĺ�SE͉��9oS�<~�*Lʥl��a��sUA�L�2�q^��h���(G�����'�Ĺ�9BQ�=ZM�'�a|�eh�͵��a��s9.t���3��LΔ��z��3�����".����n�#O����ئ���"?:�/���T�Τ�|V�7�<\!A�/^�~ǉO�;��5��g��Յ�td�Q�h]��ϟ�?�ܗAЌlÛ�țp�T�2هV2"��cv8�7���eu�]�g�f2���Lu�wx׽�rµ��ϯN��X�xD�#�\�����M�붝�y�7�����s��L��x�H?�����g�R����JZ G(¹q*W���Õ3!B�<�ɟ��E;��fW�F����
Oj=�R����=�p�Ӿ��fZ�˰u���3�8M�VZt�Ϝ@���/���(��8@�\vL��U��e�ZK���)'�E��b�R
�k`���Ԍ�nٕ+��a7~�O8z=-v
t�Q�GG*�U�?�Z���K������Ș(�� ��v��rdLُ��������"���
�o�} ���ycs�2g���_w�;^�KS�F�e��(���pS~��ے�/�p�{qO*h�,���|k��:�t�De�6�{����L���VG��7��Lɋ
�a�`s��c�������:G��:��%w�]D&�#y��av�w|���y�>�p}f�@��{D�Ȅp߫�!�R��{�����y�{4�E�)�ƣ@\�EL�ҽ�-ۺ-�w|���y�;}얋f��{�ȓ�*p���Wjq��������<�� �-Y�����U�[����ܤu��Q8�����C��#��oS��v�Ҍ%�Y�欨�7?X8�r�?/��u6�hM�����{�f-���i�������zf��.�UQj��B(��Af��4ԅ�t��d��C���VqG9u�P��N'O��'O����;�S��.���WΩ��g%�x�K�����x�;��͟���e�I��� �q�i⺯�"N���������<�H}ķNո�!P�	v*`!An�4\��#�W�ҟ���=(r7��T�G�G�{`ɉ��Əx$_󐟇���P\Z��ͼ8'�CE8M+UW�|r'��7��"N�S`.��hԓ����旳c���|�+��7�ͳ7�Z�y�l2�[�6W�87O~�'>�q�B�����[�h�u��p�%q�Qo;O�o��p/�.c-��T#�f��	q�e�{�t�����#��j�3�q�����[o���8g����𨃖�B��]8_׹_��Leڹ��}���ы�jN�F��R\(�rb�"�[Q �t9����6���Ĝ���U�5f,��J�Żu��|s~>g!É����O�y"	���k��{Rz�Ӿh���$4���� �����|���N>����K���Fa|�����db
U�Чھ�Q>������7�+1�2�w�a���@Z�.���k\&Imhd��q�0����]�. -�tpN����D�:'�>��4�g�=���� ,����C��|E'˚�=�*���{�z��Ӗ�9�w�Q�Ki��eI���h�$�l�%����j?u��W�埇�KcET5L��>j��������u�˨��ӆ�z�?=�'Eƀ�<�#?-�V��u(ŷ����<f�+���C���VPy�7�ZJwd5�ԁ;�b���G�	�����G�:��9��v<
��L5��BUp��N���
_��z���]�    8$������)]�Y��2�]{�3~���}�y�=�"�����y��h�Z��-��f��������C�����PT(N�(&�"p�R���٫~��+�����#��M��ӧ�y�<笪��Er��K}E��_�z�'
^)�:�a�HE�*vz�M��h/^#9���z��8zޢu�hA<��qRK��қ���"L���=�?�ͪS�T�I��}��u3��Ҷ�����Gγ�n��Cg������/kz�1�u�}E����s�t�d��PR/���䟩Mu�8�K�m硯���O��>W��)��/Ts��:S޴#��ꋽ�ѡ����O����(%�R8,"Uڸa��]������e�!���������=I��Z���f��>�Y��v��]!yJWig*�'XW;�8�Z�ɈS~�j��C<��/�<��{GyQlo�+g�F}��䝗�d���W�C<��$O�K��0L�n5`���	��Y��G�u��t0ᆮ�<�+�z��43z�{�=������{W.;��O�<�S�8
���~�ER�&�m�߭�K�yH:ģ<��O�,.I�F�)�Z�6�Bέ�C�� �!��)��xJ�g�Tm���l'�g��'��y��t�G7�?�)������8�S��:�.�]�5���K�x�W���C���z)�8ɟ̥�]��v������<{�ĳ�"�U]��g1�R|���l����w���`���~sO*��F����9�\I}XE&#>]���b:���ϵ�����jeB�=#�+>	_��7O���I�R���I�@ꮪi�S)�R�Z�!�q��~ǋ������59jC&>Y�}m��N��ԩ��&�	7���ʾ����đ{R1]���3�&�}U$H���:�� m.I�]v���=��o�ik�����7���O��d��ȵ����	/~�-��!���C�RW�p�!��G��o^q��g����u���1K�ҫ��hY|�z(�O{�/�썊�3����!�d�J��s�"l�=�������s! �H�=�,���H�"Bٍ�����"���g|���V�}:�@^�9i�mH��q�����ΐk�6X{��l\�{ӻ�%�x����y�hgW&®�%X�[^��>�4����t�/��PF���"�z|䑘����4�8+�Γ��zg5e�b���ݯd��Lfj'�������w�����NGA��[����f3.��ā��{>DO���<��GD՞r��U59T�}��nh�n��^��<��%��&حwV�ǷP���[\Ծ�LO���zgo�R{�u1��Z��ش��{��.���|S?�ј�4�"z�y2o���Rrj��{����Ź�(n�?v]�\GE�A��G]���8��v�<;S7�w��g�G#�>Ĥ����I����������9B�3�s�XѬ����@:�<����J�ܗY#��R�mL3$۞]]���L�я��Czn��.�n2H��>W����ʞ8��}���<�H�t'7��S�x6SPu��l��N�����iz$�*f!��U���0y��%J���O>��O���3u��������'�m�>�ث�|������t1zeR�AJT8ϙ��`��m�vx{�'�z=�X����ׄ�
��i��-Q�z�v�y��n���c����5׈��-�抦j�x�X�y��n���cz=]e�bq�9�P�[j��cB��)�>��L��w<��#8L����S�.ץߐ4U�D��~t��S�ꇠL˜���-���jjh\���������~t��S���T�:�d�ɉ�;I�cY�.;���Oy�� ϳ`D4�(��=�!Q:�E�Z��M=�G7�?���6?z#������#L3���)��<��7۟��D��� ���*u��AG��ƹ��n��Su1�3�����{��-��Y>��?/���M=��4wJ�^���0�ʌ�b]6�U<�8��[��Z�=U�*Q�[�yn��FS���LL��_1#�ט��A8�V9���D��"�/w�q��M;g@�Q$����_"��i��ȍWU���;����I'S%�Mhȓ��c����k?���|�g�Jc/�K��nᗨ�S�D�	w�ڵw�����+)q@�h�<X��@��r��ʪw�����q�*�KF�$���WlɲN;��̛_1���q_��5SV� W�욦��'�w��?��|��������X��sV�aD��
��ey�ߔ���'�5|�\(�_�Q���4/��Ѯ~���7��3�� �ڝs�تc�1�^���=�7����!d�9��B%��f1o=9�A������%�U��(c6#�RAd￧����ڗZ���	�)�@d�R"���ůx������
��J�
Eˣ��������źK�ɝMx���FW\�D�(έ�h֬-��P~l�����>m��Zӷ� ��Zr�X���+J����N}�7��8��VnרwD��N��ױl�^��S_�M;sQ.�#ᤸz�}j�.:$i�c�y�;�ӧ}h�R�7k\r���S䟵z�����:����_��ki��G� �a��+G�t��ڪ�H\[�'�{|s S0QFl��D�JVW`?RP'{���ِ�!N.3�.p�_���>��`f��xǛ��)�a�W����$��	�j�'��5��>?y5a���C���7�އq�,n-ڹ���T H�7�U��o�G>�V�p^�Sm�O^&#�)������n�<6��������Q�2��P�HA�����pCE��=�'���\��[�{/�O���HB���<�7�P�1]n���y��rn͆�ůw_1�L���~(_�Z(e���}G�)gR1���*{�/p�|����;�{���v��>>���*:_��Y>���~zd�����FrD�ʐ�s1�'���%���8�^My�W�}��T�<��VD1����4�m�+p�����f� >Q�wa�A��꒡��E�({�/p�|��_eq	<y5��<�b����.8��<�7�*�)��_(L�̽��ߩ��Z\������_�<�K�"�&���9�
'4�Hm�t�s�C<��W)O�U�T,2�fڤ^$":���Y���W���/·xt��R��t~t�H�ؚ�����	��z�+���Ʉ;��!���gR�Q,+R�á~׬��%���Щw�F_�z��3W&��ޛw�ޓ?d6��~]���.������3s��d_��}�ƹʊ��G㈲j�xN�)����e��DMy�E|�2�R�Q[�i��s��Z�$�A�~tq��h�b���s����z.�����3f�q.2�Iz��\�r��S?��:Ns���~Xǹ��|~�Z��%���xT����C�;��:KW$�eCb��YFmL�^:��#�Lw�i�S��-�*��M/䳊��w����^(��e�G����Ӧ��i��t�Xfv6C"nغ�����퇴���G������������s�F���O߼��\�����ו��3��J�9��1E�^R�"��&��l;?��t�/(=��2��4!P��z�aͬEP���.���;|A�)����k1ˬ̼�dfu)�і��𛇧|��_Pz�/heWq�ag�N(��K��]|�+i�;O.�g�����C�r'�7��J$r�_���gB��3���=�p�/(=�$��H͐7�V����j�tB���[�ۏx�������a�͵�Ϭ�S$o!�=t�N�&n;��_Pz�/�ODw߳Y^��{�����[Hi����m�!��J��!�=�t����M��}-�y����n��������

���쩿9'��Z���_��!��JO��Q��)%`�J�"��V��m�!��JO��}�9:/�<�)]ic�,�wkq�v�ѷ<��G����C���%r�١4J����v������
���K�F�sVܘj�|�ꘟ����v������JA �ƌA
�L��4*��}�6�߻;�p'���T�g���-�&�    �����u�������_Pz�/ȯ�&�a3������0A�{F7�}w�xtc�'=5��nT������+2�N$��;M�Խ��!�u���C��q��5�UJ"���G�:i:�������u��xtc�(=��j0J��(�-(����9��@Ŵ�<ģ{=驽_Z\�Y�����aJn�L��̈J�:#���n�����Xܴ�|�n6��炐�t�A����!�u���C��!�i���'�@Y�5��<��ƾLz�������$Υ�M��X�������э}��ԾLW�j�͌�P�hG���X�@�����O&��K���㬺ulqߛ6�3P�\�D������э}��Ծ���^���ɱ7gh\m��M=����C<�1w����Huef�9����J$���UP<�}��!ݘ�HO�]�\ˬΚ�g#�M5	�	e'�Oܮ}��!ݘgH�ͩz���%����9!���9��v}����<Czj��J�eR�����iu�ꔑ��߻����9wc��z��?��ݛ\yݑ����������uj�	?zq�3��t�|��Gn���h�#-��6n}w�����P�&)|QAIl�*�����k���{�Ov~�+O�mPY���??eq>�u�}�J�nGܺ��7u1����@�1��y��G�d8��|�ǐ��b9���`���ˋ���sV��e��B8�{(~�H��_���J�pDe)qC�2er�>��?B1��o�H�|��f��=SG)>�� �UU������9��ԜUD��W�fd�DQ)�����E�L�F��<��7t��S��s�(�&8"�<#k65���Z�0_��n;���9���.0\{*c/S�p�¶��#,]�[W������y�|�.El7!���]p#Ŗ�Cԁd�z(>�L��_zhΪ�T=)NBlȓa�i^�ɓjbuŝׅC>c�*=��*��/��L�r���i�&���>���K���mMȗl�+��$���JcQ��X���{�������-�:N?�yt��&��zL=��.���;���<2�ig�D�Yo:�k�b/�Eܞ�����zG�H��
5��a�J�3�p�>��#��^%��S�]��3�S�-6k%���7V.�	'�l��讏>���Μ�>5' ^t"�02��>�8O��>q�fLVҶ�#�9}jN@j���H����ԝ'��ke��D�O�w����S�;^o�5"��|V��KE|�b���k���S�]��q?=�/�l����Q�!f���~Y��ҧ��ޙЧ��$�]2�c�0&��Q��{�(E�r;���;��>U��8�@9+����T��p:�|)n���S�]�����^g��q���Wl/?V8���n]u����w�w}
�N���Ũk.3�UgA��&?̝�}��\[�µIꬒ�I�}�(	��oÒ�j{o�}?ģ��>�kW7ʬ�{��a��zS�Dlsuċo���\[õ�zp��h�F;��]���ƈ�ε�O�@��k�Suq���*R=Lƣ���%�� m��}��\[�µ����@b̒8:��p�����g������wpm}
��gY�:CR��24�Z���\*���?u���O�ڈ�%G��5�,���h��{y����\[�µ�L�/�5��{O��_&���j9�����w�*�)���4������#��4�l���{���a?u�^�O��S��h��8��o�$'����^�5����wx �1]['nP2�$�ëɱ��g-mM�܎�z/֧�b��T휢]��2��D|��H�������;x�>�������Y�.�t���K�T+�,v��w��)~�<Զ�	�����k9��ꥄ�{�7����+���#uGk#))�ՙ`��$a��I�62
l\�ԟ�jeT� O�`R�ţ�Lݴт���:6߅?��"��,�{0�3O��s�H�K�8���8���Sq�k����q�	2%�)Ķ��N8כ|,��!)�%qvS�S�K�e�ϒ��)'��/���G��ph�R���AS7-�b�@ꗍ7L'���=>+���%m^ͲP�#�wNŮ%{/2��7q�4H�TV�#YTa;���ܒ����|���>�_�c�%�2� J�o&����d���X>uW��p�z��iۺ���=㽳	�oXB�\v���!���Łd��zR��T��u��7
�|�SwU����c|kɅNV�4�}jD܌R����)|�~�y��o�r�S��F]8�2�vW�.��ϕ���G��G���z/֧�bW�te������:�_Q�*L��C>/֧���bt�����C	6���Q|�~^s��:z�էpXߝ���X���ޑ'?rl����y��:z��C���ȌUG4	'�L�hQ�|���K�]w|�8�V��a]'���@��;�PiÛ�f��]��G�xt���p�4ۄ&We�Գ����N�J�Ev��S�A����s�eY���qN�k��B"��K��ŧ�C�������#��c�<XǕ�Gy���g-�µ?u�6?�Ö�#U:�̍��K?�tEB���u���G�ξv~j_�㺄����Z����l&R��\�����6?��R$�� 6�$�d)$�v5�<��Zw�S�!��a�S8l���*����	�<S5��o]5ʎG�:���a���E���m,�ʧI��B9��w��0��7�S�fW
�᪯F]�B\�Õ6ۚ<�@�y��~�3����K��.B%q�>�y������Ə>���<9?�Ǘ��l ;����L��)�*���C>���<9?�K,�-���[�!�L΄���nر�f����w����\�.�&f	y���}_~����
%V��<��yr~*OF�K���M>�	u!m��J1�fǰ��Cܼ�'��dr��˙�!������Y&��3�6����y#O�O��(3Kf�����!c�6�!>���Ѻ�<��yr~*O�2Ks|����(�s�1�X+6��m�!n�ȓ�SyrF�I�f�z=�6�?�]4.T���B��7o����<y"��a�ir�/&�U�����^��ΏxT��+���됺,��]�µK��q��vd|�������S���q��O�8��.�:��|��uR�v~ģrg^�<5��C����٥s���Y;Q��������/w���T��]��YE���<k��?}⊭��a���A��ul���ߕS���,�ϗ�T�,�yM����ޮZ{����O��	��s,��G���47��?�/�\%:�JU3�"π_�(:�P�m���ޏ�}���"�z)�/�̗*���M)�RT6.O|�/�\���8���Cm�4N+�ނOsm��t�a�ď��ސ�5�<m���$�%��6��'�y ����M䁌��-��\����w�)������RD�3�}o�tS4/$#l3!-�vn?��ϗ;}��T�a�&�#1vS��m�9��=�l~�m�G>_���x�J[y.J�:�ٜM���W+[Trk�m�G>_��{������ƻ�e�U��u&#���*�����'�I��)��{g[c���}k��6��V�0��o7|�	7�r5]DU�d��!N�%1��9sOj�b�݂��vo�v<��s���{�]��(B"��.M��$߯�I&���Ǝ��yN��yo���oG�5J�<��I3�M��h;/~�9�_��6��R��(�i	���������]:��?�{�]v�ӓ��e�����͓oa����Yo�Ώ�yN��yo�k�[p�Rt˔H~Z��4�(&�7�0��;ω�2�w�{�9W�ә�e���)Gn0S�$��oW���~����^$έ�`��%���F!��3ٸ�G���D�������ͰC[��r~�}�n�-ѻ����G�<'���}w���bwfR(~{(���8���V]wM��y�G?�{ߦ����8�`N�J&��Z�����s�<�����.~���7���id�_��1��[��軮��������m�`���a(���Ңބ7�#o��W��M����E���-8�g\�    ��#���ގ��n�葅��.���`�����L!�v��&��פ#����<��.�ˡ{��[v���x�Ե�$S�:C[aɾ��{�_t�_ݳ�e�PG,����"/�-��Rw���V�8�臹t�k.]��Xz5��W�7�4)܊�.�q��������t�k.=̆�c΃�7&��K��5���w�񾧯���]<f0奐��u��g��
���=�N�����~���O��	K��d�G2G�q�{����u����=�/��/�ny�!���0�o�A�D$3�'j�T��G�{�_t�_݃svQ?L�~s���#q^�$���w�����Eo���-qr�!�.�eܔ�3 ���Lm��y0�������]uo+v���D�H) ����V�$7��~�����t��x��̜=\}�6G0޵-���m?����]6�K�Mq�=�"�����Q�=�);�Yk��K�{��K�]��;.��Ռz�*"�4m�y�e�@��.�8�}O_�5һx�|��������|�,��ٿ���/szל�m�iA\�!#�@Ĭ#�y�l=rΔ��Sz�GZXy�^���%��WO>���~�!�m[%�n�ڭt�{?��
���-�4�[�X���މh���kO꤯�`��sF��bbc�.��Q�bM!��^7Ϟ?���s�lSmm�;ǥ/�t������N����|���j�5�$��~f�;P��M� H���8㩿��>���b.��|��{C�ن�M��ǕC��=)DIx�#�'
�gĚHˣ��T�S��qz�>��W�Q��f2����
jZV[5�5�{�S��I��ш:I8OȌ�)�q%�A�g����Ǣ�̃�]�`1g�����䷙�du&-s�������X��y0�M'4x ���>,��Q��W����>��;����w�&\�@!�ɡ��$�)���u:Э����X���5�kn��:[����=L	�L<ٚ��@�q��������+��^�^dC�ܓ��C	������8����u薺��(\x�Õd�h����YCl��ƿ���8�:tϾ�m�����>lg�9��H:�����7��X�k�|���ay��_��l���SEp�g9��W�o|,���~^��� �X�{�׺����H=�N��㍏������-�]b�A��\.�{=�dγi�������W�y��!LnV�)�s��F�QD;��Oe�|󍏅�����-��Ƙ|Z�;�
��~�ɬیZ��=W���B_��u��,��"� y5gD�ԙ!]��.��#@�>�r��*BG�����f?�ѻ�1�?��oD��ϛ�XV���J�2�/��2a��e��su9\v�����^�ny��nYG^MG�kHR�x>����ں��O�~��w�����Z��Ѹ����fY�QW'b��y5�� !�b?����vn�(C�#�x\r�K��r}�o|�����)�D$4cG�Y��d%T�f�k���p~�o|�����i��uZ�cϱ��W�`N3,Ҳ!��q�� !|��^�ny�c5�'�+���40S�(w;):q�qo|��-�s螼Cj��xi�3D*����"-��{��	�/��.}���J����1 �y�Sc�_v�����@^���B0��G�,.�w�s���6�u���;�u�y�5�8L��i��8�pTzVr��<�� !�b?o�_�5W_W�+/��B��j��\�l��������y��Ҋs��=���H�� ��n����o|��K\w$"���ᨏ�%B�K�a��y�� !�b?o�_�ɑu����>3\�>E���qz�W���' ��*�C�|��'�ؘ�8dWs6�m��9���5���'@�إ�旼+Ji��!�}�T`�����Ņ�p�������-sk�"G�{��f�Ij�6�Q��gY����z�Y���<�ˡ{�H����'��Z\9F��U�����?ח^�'��F�>��5-OofN$�QX���7�/{�/�n�C��*i0y�Ӗ�����W���ݜ�~ܩ��`��f-�|A�v�QK5���$K��i*{�̝���f)����ȹ�1�i�v	�GЉ6���	<�.�DGJ���mK��l�,�����7�s�>��5��#�UJ�����O]HK��u�s=��eG҅�и�����T� Ӄ��Z�o�39�=�3ۈog�ź�t��L�i�k�H�>�o]�/q�M��r1N<���e����E��^e���xcᗼ�.ے.�g;up�[M�=�ei�Y���y������=�� �#ۈ2��pv�9�Q�f��M>���*�C��w7�v���Ϊ�r�Fd�)���.���w9A�%��)���o��;Ɵ�8m#�I5L�%����C��/�:tK^��	]��!d��ܦI�{^]o~�<���*�C�|����2}&�?[qu��ےr���yJ}9����C��w<�L~�HvҐ�g�2�4��&�ǕC��/�:t���j�E^�+��WH#<S�5��xݣC��}��:tK�ﳯ����?BD�y̬��0��v9����ס[�?�_K��n���n�����.e�B�/S�����u��d��fS;���\;�>.�����]�-�]��:tK�4g��6l(��R���f��B��^W����u���Z��&pr���|T>kُ������_��M�!q��R�7�x��5O[�&�)Ƹq�������-�q"2���3Պ';�}��g��6�7$�̇�]��F�܀�ﾡ��� ��ʭ9]en��o�H~����C�
rL;�����.��Ǎ%A����?�_�.䮹�8�w.5�b��OK]u5H�b~M��|�/8���������r��.�hx������ʆ�hV[�R��g<@�d�_�R��-<@�LO����(��V�n�� ��{9tO=�t�"��^��i
驑n�IZ#e8���>=��DDNe���$L���g9@��7_�R��D69�,�~�J ��ɤDƉ<�m�z���o���Χa����o��G9�$�ՕBgL�G��_��/����@ ��+��䧕��oz���T�8� �9tϼ�U���o(H���9|c"(�+l���9�[ݒ�]�7�!�D�9��]�uۥWރ!|�C^�rߑ��-�.���Ò�N�P��id�vޝ�ѧ����=���0�I�9� �Ρ�&	���t�<���{g/�n��t�-��瓋�b�MdK;��P��y�G�C��w͢jMZ��S���>[�!H�[�����n�D������-�����p�s���ɳ��������!~�?_�b?kL�~w&���Ij$̡�6mC�,�� �����C����(�L��k �.�&��/4��8���8���=�{���W!oLçY-e��\[����#{�W|���P����O�m0�}X��2�u��G�~Ƿ��?���5�����ȧ:b#O1=ZMW~ԋW��[�`�pVWBIB��9�r����k�D����'�����|v�a�W>9�2��Qq9V���>�i��A�J	.7�����NɫVSA�d�(�����<��'��5��G�O�77�M��7�Q`����g�'���X��*)�G��4�
�#��|�\��8O�qO�a�H�������h���oT�����/Y����^��ꔮ���'N�Ri�ͱ�����~��wul_ݓ���N�k�}mO�B2��UH���_����ݴ���;����րH����֓�Z�[��������KO����g�k�)M��+��SRp��4�n��w�$;qH䐻��w��c8s�3(n��s}�?$#�C������ |�3�{���Y����kۈ�];�S��|�c����[������[�׉[�G��v)�}Os���-N���E�{�F�����䠫��3��8;��ġ�>#�f�)+:^3����>α��%�D�1
~�H���CaX�K�ed�>\���Ĺ�D���~�@(���Sf$i�:�� �[�����z�B��̾�]R�)��{?��q    ܗٗ�s���13�]
�T�~G�'� ή��e��E�eR{��xm�����P�>��=t�/)����l2��6bi~��fs[?.��=��7[И�8ϐ��#Y�J��J�p��у8zZ<�hVn�b��?q�a�m�e-��q����:���n��s�r��zr�TJH&5���F6Γ?zg������R��4��3��r�� ��=���9%;�hO��� �%׌+���&��q��у8{�$S*ul).ĉP��#P����)r�Gy5_��&��L^\�J�h!SR����.�.�$N��*���}&��8�~������=��E߼�-Y���}�U������)�$�� q��'Ǚ4ǼB��m�������ſ�n���]s6�q��1W���.����n����I��I[2�0B��iSl���k�{����ѓ8a��ޛ��5��׆gg�Nt�i�X�����ȟ���C��!+-�=�[ȋ%Ir3Z��F���{���c����-�13:^�w�Kʼ�z=�$+V��	����>�ˡ{�:����s��T�dz�q��B�����{|��o����4�0���}mk�Mx����5,�yZ��{�/~ѩ9t��쭖�G�u�N�ufp��,ϊ����!|�Ӿ�g9�8���o�����$XͤT������Ο��^�R6sS�q~�'��Q2Kʴ~��/�o}��y����=��H��F4dK�9X���Mym�� ��L�C�ԓ�*�l��?���ezK�"u'}�|�kѩ9tO=9F��?"�/��B��l�o���5x�q���/:�/�n�C����[oN��q�]%�ue�	�7T>�n����t*���/!J"�I0cu/2��nχ�7T>�Y���o���(�|�u�X��V�֮{���/�!�6>��}$��N�ny���!g��羿���yo���=y\ip���}���e��$�t�rn�o�7T>�/�����R�^h�E�B���}کH����.�����9��C���&�8;Ȼ5Դe�<�.u|�Ï���?*�y�^��}v��f�r�V2ɒ��]��3 |��z9t����R(��>l�~1��{#"��o����#o�ˡ[�Rr#�����oF#>�"�7|����y�G�X^�'��ᅲqK�����k#Ք��uε�{:���<'/�n�>7��D����2�%�@��8�q���~�ˡ[�{���%�#>�(��Lqv���?��}�9����#;���x�u�v�MR��k�qr:���s�/���m�)�ι<�ݏK�=�?v\8����ˡ[�Oܖ$!�/�"�c�����]$v��y�<���rW�BP�=�@��0p��L"K��i����C���_�g��y"��Q9��ӞJ�Fm-�Qj�Ϡ�]�k�����^�� B&g���IA���t^,½�1��?����r���H���čqH&�Q��L|���q>�=O{�}l��!��[o_�����:Vѹ�?�3��ܯ����j��\�`x�v�:z�'��=�'?8O��/tE3n>�繖Bҵ5�P�[�!��P��0�i��S�.��W�w�J��˞�M���'�~��?r!3�n�sŬꆅu��Χ�����C��]غ<��|P��Jrb|��H^�^�2�4G� �U��nW�:����^y'O�ģ2��s���~�ߑ{*>o9���a���%j�-��>ס��eo��C��w��-��7�>IjkA���l��͓ܡ��$N2u8O�r��3��#�BiS�~�c�������8��5���&�K��p�E�8��۾����y\�?o?땿��_la���T9�%�h
�6S��kI���89�w�^�ӗ	~$M&
y ��.�K���~��9 |�?���R�! ��q�Κ���>��2�CN{=�KUmp2"��@���`�9R�rQ�W�0"9��Guĸa��lq���M��߻wVfB����Q<=������*���!H�0�s	�&�q�S��`�Z��8:2y�
� ��_-U�{��g>��=�����%�z�qr�I���}j�sk�4���N�%�ڑt�9E|���r��ҫn�����<���y�ZJi� n��E���}I1h^mn���1��Z$�x�"��2�s2LJsh���ݟ���a<������Ͽ�0�o�<W�,v��OsA�l5g$ �'S:7c��]�k��W�i.�}���C\c��4�
�GԽ���X�������?���Y�:�#)`�J>��yY��T�s���?���Nϱ�&���#?;�2�-8g��x�A�p53sZ-/�ZB���p9�gJ��=��O��/�\wՓG���D�H�:���y�g�u���?z�K ��d})j�+℥��T_�~�?��'q.�����6���d��~�M7���g�3NIՈ��j��� F�O��v�<��_��n��"I=�&
�"k�}���#X��p�����鄻����w�z'�WkM�����䏞|���TV7y�v��4M�q\��������I�&�C�dݛ{�ȏ�o�i1���N��=����|�s�� q�p�s��Qt�V�W�Gm��|8��q�`] �:�P��e�&���= O��3��у8ɖ����)�@���&��W�G��qr8��q.� ��-*u��4e���5�Hi�k~>���/�\7�Q7DH��l���:b=�`)j���L���1�`x�/V7�ӄ���N3���
h��g<��q8G7�v����'���$���v�O��A����S[&��*��!�2֏.��0�����~��iN����{�Ŏ��M�VϷ,u��u�!���Y:��dO^�I]!��|�Kkv�p��ѓ8k��,额�1m�FF��1�l���ݿ�n��x��=���n��X-MI������6�����)��9�Q�s�Vq�'׹�[��rݣ�?z�*9G_p�y�Y��?
��̱J3�.�ѓ8G�3f.��������ي��Զ�����M�2}�����L������&���������sk��|��[�r薼�p���)��P'�t��ZG����?sz��m��ϡ{���(��{g�q��;�o�2��U�>W~��m?�ϡ{���%"��u��WL��˶6k���{y���r��3��Ң�y�GD'u1
���R��T��C��?�r�����௉����eV��nr}-a\��B�:G���-�'ҢE�w�r�uE�!��z��!��e��y��m��ϡ{�l(��&�Дq�[����э��^>�_��k4K��l��.qy�0.౶^���.�������?�n�'OM��7#r����3��.�O������_݁����l�d+���yE����ӵZ��:�<�����Ռkdd�� �$�YC¥����2jqUv_�4�`_{�5\C�)��ރ��2m�"T
�{�#PO� �~ǟC��ρ�w��D��0����)IEg���{9Ax��]�D�z#]yߩ`�����RG��z���N������R�U��{�i+S8i+�r���Pgx2��nԄ���[�Էk3���6�6��M:���YV�S��@�y)d�6���[ot��Pg��C��{����1�AZ�x	γ-I�去���ӦC��I�=4JZ$D��ɀ�O6W���S��,�O���#��U��:�'GNX�d����ӦS��A�L�
	�H�N>�����ձ�O��+�<�~�g�����+o{���_@M��/��u�t�3<�3�Xmod�w�P����F���^��Tgx��=�u��&��3a?��9T[�]�'��	ܴ4qk
�&3���`���ť��|>��'� �&ͦDBŢ�WdK;�e������4p��ѓ��+_�0y8��z��cR�o�1���=�'�K��&��V��*մ�[�K�uΈ4n�%v\�����)���uF� �ď6�� Z�ţ�O��A�I��ti���@qiLw����mƐO��A��)25�M�y<Y������+"�    �?���~oL�ܮ�[���'�Vd bI�?�:�~3��у8��.���`�=��Y#G���&�y�>B>��q��W����O`�ץ3�9��5T��Y|�.لȓ�
n>׻F#	��Y�^O9��_��7�%%Q�>s��_*7N#�V�������у8����tf��C2�Ɣgw�ݎ���=��Ed�9{���e�ʕ3�(c=���j����~�kߥg�t .f�u�9���C��YV�|��y�G��#�vC�`?B��a�nXq:��G��ę!G����݊-]<�^g���oYw�����`��/�9t���p;�������
�Y	���N�ʵ�_����G���C��RQ��Ԅ$)�ա�7g�p����wV����G���C��F$�e @ʴ����E�
�9��W�����=ӗC�̩�9�j��؈M_m�vJqW��~ |���s�����qR�}X�PZXlv ���w?.��>�ˡ[�(���Ȍ���9g����Q�ֵf��M=@p_��ס{�{��DFc��m~Ŵ/�ںs$���8�����ס[�:dG�#,.y�G�^-,��]B���G�w?&��şC�|��:�hƢ���!�ď�O��~\<��w?��>�u��3WIH���!���2�J	�A^'Cw�봿�`?�`��d#-'�%�|,
�t�Ja���?�o>�gګ�i�qda	\�P����)����ǅS���~��^S3���"^�x��a�*�La����$βd��x)��
�7�6��	SO��{:�]<�7��Q���ϵl���}�l���|�o�z��		��߬sS]PΣ��l���x�?�h�r-��91�,H?C�>W��n�'=�uCL-Q=�U�8���V�|-϶��RN��'�8����0/.���ed��}Ҫa��ʩ�� N}�)��N8�X�i�s�1�@,�q�ӖS}闹ߛ��ª�6��L]��x)5L9* #>��S��Y�K=$7��Ž�����]�Րv�SO��q�J�4!�$oL���C����3���y�՗�g>�C��a���p=R7v�R?�SE��~������,Nݪ�s!�z�#1��G.N��x��[}�Y�Ѽ��!a���h
�pVqqY��Z����g�,ΘC��pV�e��y��4j;ڊ�v_�]���+9t�`�'��[�*:/Ŏ��oHJ6�7�,���#G7�A�DP�ˌ�������揞�Y�hA|�}�{��g�����B�����z��3��ˡ[�`�ҫ��R'�U���Lq�ӄH8㻞�8���FA�N���mԚ�KV]э��=���P<K�_���o�t��l��z��]��Y�}�^)X|��<�eBS�iz�������Ĺ\��h8R{�qjE"��s�PH�q����9�*�d�)o�3�~+�CG+++�\��y�G�Dܦ�q ċ���&��p�d���~�GO��%͉ )O�?j��G�D״T'�������9�.FWdHa9S��`&�r�擻2g����=��[�za(���<�XȻE�b�Y���y�G�T<�:��oj�l�T�X��á�����g��~�1{9t�Y�M k�/!2����m���t�
�Ɵ |��9tϾ��z��#X��s�ti�Ԗ���[���W�͙4������2�JNF�p��g�H9�hγ�ٙ�3r��!��n�����w��g^�$_�}v��&y�I��w���{��;^���g�Ueʞ�>E�q!��o?�]z=ٞ!<�<�ZMOu��|�=��9St���6��)��C��w�#� �-l�rt�]H�����Ͱ���5��/p�RgMH���W��|���O~"��<-p������	Q�'Ww:���b�!o��Qg���-�{�pKZ��@{�Ψdo�5Y$ 1���yw��=�wVm�u:��#�8����1.X��w������ˡ[��"<B��<Q�T�h�����Y��\��c}���m�@��v�r������R��>W����Wv:Z-����\=d�n>w--o��r�7|��յ�RWbγoH]K8���L8%���þ��#����'�G1O��"MN�{]å�~��	�/��ݤ4f���]䅋�mp�=מ�
���;�R<�w��fQ��}��}PQ��U���y�/}�K�w�H��B^T���;���ì����ң��K�,�%�3�`�ﷶ`7�;ܑT��s�8O��q&�rKx��T�����ڌ���/��<՗��{���*�m�Jf��ɞ[���%���e�<՗�Yk���ab��'�jAbrn�G��4w�NN��q��,<��ɧJf͝<Q��wk}��d9՗��|s�S6��|(�Tu�t��XYj��ѩ��}.��5�6b�c*�͊P) a�|]5RT��u��T_zgBбH�8V�n��\Ph&.m���{_&�3��p"Z���d�[���ɼ#�8-R����>��=�S�J4��XI�K�x��X�o��N���|��Ko�u��7!���#���0��
���ȝ�у8�Zu5�#���;u�;}���p��у8;�������{�4B_�\s��O���>O��A�2Զ%�$�yqr�<΅M��o�'�}�e�%��}����w��Q\��"&U��#7w��]W�Y��#���;�k�[�~\ge9�i½�h�{t�GO>O;���!0��ݲC33�$��	u���w]�/:8/�n�+v�)eK��H��
���B���=��u1��)�Z�QR^ԗ)�>��٘�,�������,��h��Z�3 "Q8��i���������t���K��C��Tʗ�n�~��yڔ��������u~�ϡ{��}xGuн_��"'yc��:緎m���G^��C��]���"���<��WN��o�;7�ƙ�����i����'F�ap�8H4�M\������Y��������mG�B�Nˈ��eW�n��w��^݂ӆ	���{G�a
����6����	�/��&]6��I��oX�e�5e���XA�ϟ��䅣Rc���
_�_�ϰJ�Ӗ�����o��}� i���E�!��%&K~JB��'��nε�,c�6k�I$vC�Į0�~�����#�Jo�y�2WL=�ՒR,!�ݗ�'~��e$�Kucg���u�=�X@���8���|���C�?O��c9��z3.��~�o�b=�ܗx�:f�>�dܨ�z]�Z�p�m�B=ܣ'�H�Bd�I��k���o�@A+R��̟p>��Hda��BCK��F�t��ϵ�?u��q�ˡ[�q>��*��/-L鳛��:�;l���w�,��\�g�Li��]+!凞:#)ΥI�:���ٳ8^"�������'eXki��d��8u������-�g��A�&6����������ܺ�)[G,��=�N�z&n�uF�Kǵ�+�J�^�ʋu�'q�❥��/�z�zBK!�Ifz���zg����ɫ�p���-p��hKI���]�~���{���QI�c)��W8O������]�y�;{���9�ɟ,�����hC4'�~�<���F
�q;���u����x�N���q��у8�4%����<��c~4]s�l=���w�%�x9tO7C�Z�N�tAM�x�tϹi�c��w��gq���"�����{/ilR�?�jrۿ��=��"{�$���#.��*�y)�ig�����w�,N���������6�<�ۥQS��G�zg_�͗C���&_����#�E���eҫ�\ZU{���Ξũa�Wl����3�(�b
Mj�����ξ��/�n�7��FV�h���<;�����|�y�Gⴖڕ\�M!����3��@���ֵ��zg���H����F�]���#
~+t�O~���=������֑g=�)�T�|�6Z�eZ��{��w�e����-y��8�|��㫦ڡf�͒R�m���Ξ�)�hE�i���A��ϗ�!#h�%ˎ���Ξ�Y�+[����\=b�!HB:|��w��gq�EI�ʽ=�K    ��)'�ܩ/��ѻ�ٳ8L;º��cϭ�cR�����LY����ϥ_�����*9�$k��<�Ɵ������<���ǝx������gn�"��ɪ�`�%m�ϱ�)aFv��4G�`ݛF=��������ȟ�ȗ�G�@��Ϳt�5zp.�5��v��]�R#73-�2�K_�4?�`=9L����gΩ��W��)��he�����/�2f�S�8#럓��ꖃ��}�bO<Q֓�Z� �c�v���e�1S'黟}����'��y�� k�\c���6� ����w��/}��C��u��.Bb(�U�߽�ُ��%['4��E>��|��D��X����q�(��{n>���+�,�)d�D���|�s���4(�S:�����b�^�3��X����`~
e���#U��y���qJ��ݡ���{��~��3��Uk
�������8CX���K�s��s޴�l������y����3w�fG�LV�O_ؖmK�j�k.�]W�?z9t����M���7;q
'0��h�u�����x�I���U�N�B���;"�GR�t^{R�B���$�3pοQ����)H����/�+�ſ��g�(��L�D���`x��O��?���]W�Y�.�T��8'u��rŚ\z���h׼������3��TќG��H��4��D�ō���>�K/�n������5�$�!�JU��9]�û�.��(�8��H�P�D�
����"ϴ6����>��I�� � ?��'ʑG�PgyH�eV���B��L0��fz��E��a:�|�Z�Zv��]W��S}9t��Ԟ�lb�μ��-���IN����ѻ�г8gHk���g�}$�M}5✌:\wy�]��
=��+���T3�W��w%)`��M��%^8O�����x#z.F��rަR����F����z� ���r7��Do��04�8�Y�ϗH��V�~��B���!Sc=Dp�j�\>z�����]W���iC��F
y )n��P���+[6�m��+����M{�+w?��2�s�wk4�I�j��Ԯ�����t$��:����Nc�Z+ �_nǟ�B��D(�"n�<�ÿ/��Tmix��_��w]!�y���-}��(؀��2^�Dh��C�#Ljձ��;��8m$8�jFb�x�#��[;�~D�᪇��?����!d3+�qT�G��J���ؓ^8O��A���5�lF��1��f����u�Թ�v���C�?�4���>o�ʴ8'�X�O����\����<����v�R>��~%��B2�-��ft9�>��֓�O�y����-qH�aƔ�*���}]���$9� qm3��������;|��U��-2:�B{��d�6�p��>���-y�8ꚩ[9��/�
����[���{<@��7�s�~��ɮ&\#��~3)\rs%��L_���҇�v��9UW�	�T�2X7(��[ܼp�������Y2L�7�qO?kْl0�q�E&�q흕�/�2��ޓm{�o��S:`���G�������r������C�̇�)�6XU�w��W1�[ {H��\���Æ/<Q/��ك���Sl � K��u)����
���/�F/�n�KY;;�����瓋�3	�:����L��qF V��>.�2��R�$�����ǅ/<</�n��ɍ�x{"�D�i!D��:�3�I�8����|g�Չ���:��N�.�l}9�.��o���7���=�u=â�CޭD��Ȟ
�j�~Gv��9���G���Ms�Iȑ��1����1﹵��﹠��O���=�G)QC�o{��}��Rr�:.<q����]�/ܶ'�&�\����"�M��Z����������a�y��x��#��=jx�=4�5��N��O��I��鬊A���>ي1�U$�cY%_�?��o��C���)N<�h(��*���9~#~D+5 ��8O��A��zE�Lfr`6M�ޛ���:d͙�bv�~�Cn�+�\���1p�B�J0�l2l@�dca^�}>�u��.���~�EQ�����=�����Ȱ�x����o{Є�u��:tK�TS�6�Eﾌ�u0˶욲��^p�7�@����r�{����l8�E^��MYI���������ٓ���J)������:�k��t�j�v����'�������-q����&z�[�4��d#�^�B'��'q/s��"��C���%���X����~�{?�Ӎ\KKm��Ok�o؍���3�w�;{������'�O*�A��k$#�2��n����/sV7��8;��f��R}�{(3�]X�:�՗9�=��Z�M:>H����π�NZN����'��'q���v��.s.(|���Kl�����w�Qo���-�`.�%lp���"���)nI��m�a�<Խ���S�D�Y��>�g�UL5eWH!�7΃?z�˳:�()�BC�wO���d"�\�_�NzgO�s9ׄ(��!�g�^���h�K�8p��G]��C�|�m�p����n�+�x�T��[�p�ѓ8{�p���"߅��Y␄ĩ��w�/���ٓ8��W�l�R�( ����2v��O�U���I����ˡ[�ъk�<M��������H�-����7�c��+?؟C��ŵ���ݤ̾!ytf��+�� �8��}�m.hT��Z\�ʒv)��~/�B��[�W��q��3���K.y�;��y�m���y�@����8���H�s
����I�P׳�6��������l#��}A��u��w��XІ;���)_���}Z��<b#��l��H?�h �`��}wo��gq�d�q���v>S�%.�S�>�ݹ݇uo��gq#����RM�[�M�:,$��?����)_�?��%�/u��Q	��L�u��&��/>U��ߔ�~���-���'�N�{�/�n��.d�����T����}�}�|��ND����GZJ�&��t~�����'�����-�38K���׺�8�3G�R�>m����۾��C�ğ��S�da�Z��)���V��7�å��(|�ه��.���SJ
��4�4�C�m��(�������X���C���L��poW�`3a$d ���/v�+>�ׂ��/[��gY]@��kLQ���	�3)$���	�OÕ$���ȱ�
�����O��m˭VD�b�_W���!��)�+����|���8��T���B�]�=p�-�ܓH�8��ƙ�Bj����C݁6,I���C@���{�`���r�j\#�U�%mH�b9fն}���c8c�>�ja���lH5�Gx?\i��%z�G��n���E$B>U�?I��{e�(���h�;{���<C���IE�I�+ߒi�t"M�� �-�y��=zr����l|��ߴ�A��S�m��KǞg8̱<9��
�H��y����O��;��@�g�}����6����� "_��u�ĩ��#T�K���#��on�$C9��E�ߴ�:�D�]5'�<��Mw�a���P�_A�gJ�W�uRBJ�7�'#�<���<<�6�,E즩ɳ>�iz�sC��8����m����C��+��#���?���(k�vQR���^N��t_P2u:5nۥ��#���S�쒞��/��&��+�p����Xl@�ѫO]�{�ꍇ'��kn㑈�B��;��G��g+��۳#���=v����œ��4rpf�T58�n�N�׈��U��������`}]ֽu��,���S�i�ڦ�!�=�v�KO�Dz1]'�Yb�p!�׆�ƙ;�5�7���� ���+}��"5�B����M_S������skڒ�6v#�8-Rb�8pJ�Z��_�(��??��^����#o]��8d,1��ЗG�G>�<ܣGq��D|R��z�\7��+���;�#<X��ϴ�+�V��R�?"o������b�<ͭ=YY+皥10&�*"�F��6��C����i���z\����B�^��c��G#�KC(���MW�q��2��;w���b����%�p�8�{=oz=��=�-y9�G���9`NY����:    é��`��\�fC������9�`�h��ci�>©��`�.Y�� Q�K�3��v�46�����|g�sQ���H�Lmn�kj�K[y��>��^fk$�k��99��?*��-ĸ�6�`���7�I:)��,�:��Z�x��\��H���i��I��/$ԉ8�$v����15gX�8��W^|����ǅ����-��ʐ8��5�P���t�����B=�����z���� g�r��דO��83.LZ�{��[|�LCrM��G���}/�����]���S
��:�`���\t=�7�z]9��'qƥ�R��e�O�1�ik�$$wY�=�S=��:C�\��j��҇�,:���R\;���p.!<Vg(���A���G�G�����Ԅ y�s���'���C���긇d+̔oE]-d����)/~0���J����道���j�@��g:��o|�3π�ɯ���	L����K�I����~~��s薺M+��02<y�aIk�窢aq�n~o��O�Df�Ĩ��A}P*d�f#H��@��v�ۗS}��}.;+nP+�*i�
�!���7�ua�E�S����ˡ{�X��u�D���=@&���E����6���9�?�ny�p;y ���Sޮ�����2-h�����'�6S�L$.kB�	��k*H�kA0����^N{�O�Q���� ˴F˶��d7���Y�=��<9�m%/ܗ`z����sA��R-�ڭV�8{=O�\��	9�!66�.�F�����}�$g�=�Qc�H�WܺKL#��H^��W+�7��^�/|�7�ڨ�:��\���6kl��)3"��8O{=��Y�J�n�+:SjA��K/Amt[6�i��A�S2��'�q��وBMוc�3���]N{=O���	��.}�;�@�� �+\�u�������K�1Pdv�I+#B��L��֚�y���i��A�+��Vj�ۋ�q��aB�X9��{t��ygE����dý]֓��ɯCO>��[����Yt��B2�䯁����?���l�?��r�G���4�ޮ#;�T�\���Ӣ4.�u�n]���Ù<,�>�>�dZE��q�cH@j������s��S��G�*�%gj�%�v�UF�=n�-��`�+�����:�!�ޫ��ã#`�v�eNsVO��Tl.��S�y���S&��V�5��ѩ/���g/"C
�O�#�����}K:��8�{?��<�?
���,��E��w��'��ؖ��>�==��2�{�^=�W�E�s:}A���=gu��=9��F�kp�6��"��6���s���9Uw�=8�9�����6�g��D����噱�x��Ns���|�}�)��M��Hg5V$$׼�;�M<�?�-/��2i�D�L}.��U�y���N<QO�$�c�M̑����0�i+��t��9�o�}.B��U�Z���K-�S��z	0V}��t�{pNI%?�nl����T��S�@d���t�9�'��Ử�M���G6O�e|�J�:��|�^����i9�Eȼ��ɼC�A��<ق���ٟ�'q��+�������Ž�ڹn���4[8����x�d� ��w�c����H��i��I���o�D��Sgµ�ĥ����T����;=��2�z�Be]l��̤�x���{d��Ӝ��8�tY�h����1�Gx_-B�ҢK{����y��$����;�_��|��ݞ���}o��A)���T#��-x�4�X��w��'�
r�d�I�w�.ْ�F\��:��}'��d�s��R�+�yj �U3�ή)Qxu�N��'�!l��ȏ�#Fj�&�v=�0ź���TO�E��t����ęLQ��B�̈́�rg���q����D2�J�4l�uyG��8
÷8툻�N��q��8a�E��� ^r&��@z=�S=�A��N�q�Q���⍒�i�!H���Ϳ�N��_x5o�gP����3.�ᾇMY�H�q����t�Xs�QO��nԏbl�-T�$}n�=w�'�����G�Mlb��7��or^=��|��q����e���J�q�/d#"�VdN�e���éȄŧB�ֽ�"e�:��i�5m���O��ț�C���a�J=��9��O�F+���O�G�D�3��$��ԓ�=R\z����H��q��у8�
������W����8)"�'_�Qi�<��qZy'$�s�sAM��v�Y��un�~�7�E�ˊj֤�DR��n��Ҳ����.��?zg�q�M��|�:=���ɮ�.��$�6$-�Y��:����W�|��"#_��ѩ���>״u�f�~R_f�����w���}�De�'��'�mf��d|$ov��@�ܥT?%R�o���c~��+�$���eq_)G�=��ZK�?���3%�s�6�قW.N�8M��4)[�'p���7���|gxƒ�W�����[Ql���}z���r�x�oH��l#Sj7)�;���ٮM��u09��>����k����@�fJ@�4i�|X�o�ѓ]zr?��C@B4�.�J��g\�e���{��|��RF�<�7�.��"N��������g��T_z��i��~wK1�wߋJ�wm�<Xv�9�G�z��W��Yd���G�/n~���˿��N����fkd8p0�]��1-�:D�ɹ�<;�[_Ɲtp��n�WWM�B���i�A&����9��]<����>�h�=���1"?�ei�}�t�?z�o�ߛ��ݤZa���!Tr��.ZK��o̩��>W
���%<���.Δ�:�R�ڹ�0��<��'����J��YW����\���\�֓��'�X4��GY��6Op���t ��5/ޘS��I���J�p��,�!3��:˔����ǝ�.�';���w�؇���ɧ>����zR�?�\m�� ��.���A^#�D|m����7]�?���k;��֋$5�'윪C���}��}�'uĊ�e��"G�B�d@�{�2�W���'��G��f��*�:�zRA��g�ҾV�s�u����d�,d�Z��I�OV�4^z�ts ��sA�����.�������a�
޻���@���ދ<�>�o�y�v"�4��:����%1�[����}��$�\�ɪԩ��T��"���*��ǟ���8��<y�
����(b`��kC2q{�>�܋t���N#�"^�"����>�!����8���M�BX�ㆧ�C[kd@�s�JN��q��'��T���yt��"�7��몮]����$�.���R�'�5L�-Z^"K$Kw=$��랜��%"������"BO�+�Ⲇ��Y�|�i�A��鬌;��J��.E�G�tI���P���d}>��F���!��]q�:�w�P�#��W_�Ї��4����Y�\5�V�u0�����~���Z�{�"�!<�sL���{�$;r�itE4� p�w�q�K���gy��R�!�����D1��p���!e�2��()�1�����x�p؛v��m��a�}oD��P�t�t�J�[�M8�:?ze~)��ig(�i�m�҇>s���;8�M;{B�T�����VK<N��WD��w�������%��_��T��p%3�B� �����{�i��"~��}��-,�L�A�q�����ֵL�4?��7#�!�q\uT񦥤�,D��ӺӜ�M���:P73l*�'�o��o�g_g۸�	�hgn~�.^d��Q����*k�%c�iO���{R8<]d<j��F�i��v@��{?Ο�8BP�<��[{�CX!���YV�ļ7�p�?�؟O6��G7����l��@f_źPC��yµo����
,�z���h���3{����6Wq��s�G����,��d�#]n���6�p�{_�S�zp�Q�i����9ٰF*�m�e�cL�ȳ���P�C����;M_�uGNʯn^�S��&��k�4
k���N~�i&LC.�������hgF!�<�ϱ�����j��,H��2�9_N��&.�Z�`���\l�d6��z�R�8�?�ӿٟ����X�ȝy2�;�8}�E��H�v���c^��G.��j���9�YP�Q�s�C!��<�    Wy���9��[��_"�XQ�iA|B�k���Ӟ�MA
,�+�y*�怉RD9�mϽ�2��y�纺��F�ĵ%���j��m56S��e���8�\�F�J=�U���EH{2�T
��K'|�b�怬�}Z�8u���V\D�7��uG��o������2�ݑ�s?.t�ɨ�������S<�ٟ�Vq�#]'��uo��Fu7��+�ƹ�N��o��z������h�E	��-�I�L|�ȓZ�<{�y������%!��&��@�7�\ӯRd�8�I_榝Vm�K2�'q�ä�b���|x O��7�ީh�l��D�}z*W��F�+7W�ޛ�Ü��>�mk��DJ����=��i+#���û%�9��v">�Q�0:�/�N?�� C��~�<���'/���Z�ph�$5�D�XjzҸ\#��毓Ӝ�E;�Í�y��N܇ݼ��0������>}��q�N|%���y���R�6A݁C�+8�s�'���5y'�s�FBT���3��k�*5o�C�&\��;%U>.���=Sow�Ȩf��m�KOx�E;�u���'Qb�<g��xﳔ9�/�{|z�;��זw�d�X.x�6���#�l.tT�ڟ�#=��W<$�2�qPT��E��J��B���>O���y��Y�<D-y5Q����]�1	��7��.�Yq��sV�4�g@�YK�@�#he�������זw�b�'���8oC�E�)�B^�6V�:#�4wqs�k�R��b�N/���Ld�.z[��ｳ~tq��;�t�tfI��'gM/��{�y�s��*��q�6jI���ι�&yr�+��ǝ��n��e�>�_�u�Hu�P��ZZ�@{OJO��E����q�;	���{[d���Vr�3p���?�������I�.� �Cюb������>�U|ӷtq1�<'��8c�U�\nH�������>��f�f��-m`��P�#��Cq'}��v:�D�
�-�%���%΂�p!�l��4�v߬�f�5�Py�7*��M���#C�Έ?�ݴ���.VU�%�p�2��RY���h�I�to�tB�ԋ���^d�=��<U�p����to����J����4�d�*eX˃�?�;������!�EAP��Rk��3���O{�7�,:��홤<E����Kir�����J��~��N�
�a�F�'w���3�*�R��;;��7��Ieˎl��w*���zs4�gpH��<m���ȋ�\�,�TV��?s���3�+�*[O�4�~s�lV�Y���P�!�`��ȗd��W'���aO8�E;׈�� Ɠ<���ם0b���d����d������b�.�/!k&oa5�}	����'��<�SK�ٛ ���_ZÌ��!j����9�p/֎#Y�pp���>)g-��]��-[\�T�+�h���������}���v��&�D��CI�;(����:u��wv�O�H�\z�@p.�	�!*���}���=��k{��RoWa�t��i	UNmJ8����=���2��Mv�W���$�ia.�ΰq��MG�$f
js�馩�"(�̍
�!��ÞM�fg�lˊ�Ӓ�v�9��uceO1���7O�7qX�a��-�����D~�~-8ֹ���s]���%#@"1���x�O��Y�W�u�q¹.ڙ�s�k���njB�_��lx���'���Jy����cgDFԗI��9(?�\�a�����l�5;s�������O%ȦA�R�O�[�)�p��v/���s{��J�jEz�,Ů�ۺ���s]��"G�5&���^dk�g[+ΖS��'��^My)����I�[�{��	��D~�G�s]�Ӌ�H�ȯ�����:'�m3&��%{>$�p��v���op�<�v";�g�Zi���x�<�\��U�K<���R3���:����Q���67.���>����J�L����̩V�-"��\���щ��>WV'�73���J�7Ø&h��c����݉��&~4��:
�@�٧�LFv�)1={R��覝���Μ	�}��ɠ�毛��;���Ӿ�E�h� n,�:�����-M���6�"���ǝ�P��+�$k�b�u�'��s&��)�U��ϻ�^�M����Cc7s��-���j��ؖ���w?
y*��p�=��"!X����=8\�����c<�:��Ng�l^#��L��YH���m����7�c^iځ)�������9�@��0V�{O���qs/2,�	�ؔ��SVE}�o�,�H���u�y¹.��}ȕ*gs��N��DrbY�,M�m;�i��"�lM�Q��g�DD��ٗu�ɛ��t�+|�2�Q]rN�U$�E{�y/c��U<��#��{'��{ej���}�s�ԯ��si�y&k�D���F�0g���|�{?����WG�a)cd�ij\��[F0��m�ϓ���sedr����1����P�(����q.���8J����[��YS9N�|D����>v�����V��̃�23�WeH��@U����N��7�?53_�~��AG�c+���ǝ!�k8,Y6��J�9?��Cl,[���N���}�P3J��Q�#U�F]�A>�����X6o�I�&�0�-�dfb܌�gǵ
�t�حs?*��͋��*����}�V*u��Q8%�h����ϟ��ˆ�zd9Z�+���v�5�Ѣi�s�x�n�%R�59SG��e��h�����2���~��}���Y���9�M�H�a�u$]
���y�N{gy�ʲ�VK*+�w���IF�1F��uzt[�	��د2�8���%c��i�5�ɢ�QWyt��	��hg���=}NSJǧ	OM�=�
��{�,p��Nߩ�$؉����^O��{(��n��I�����لkv�̃K�ӱ.FrG� �~Xך%m!p��v"��Y.x�����C�x���zzp�t�e�^8}�f΁�"f9�E�F>�V����_��g:�27��p��GC�#8�kw��v�������\榝�W�K}�9��SD��S��G�9O;��M;��?t�����Q�w�f.��}Y훷0p�foW_�Ovކ)�C�~���qaV���p�=�q��n�Y}��I0Jr#mqοQ��[��?���n�)~��/k"�v��`�po�.u2�ݩ.���K�����C�S�tq��!�'Fq�5�׮��)��ɯ�HiQ�E��ﳒ��!x.�[%I�{(���M<.���k¨ԃ��Y�C�f�V�m���~��3MF����u\��Gz�U}-#?�\g���"���sd���Nk������8�}�N�67q���N4;�D騐q��	���G(#n\�4��
^]H�8}�5�,+�^ى�֟��O����Zȫ��	�g#8�z_�2a��;N}�xG����W8vO��e�M\�B�!��_wڇ��'��p�B<�_�iWNi9�����x\<��/�+��қI���|k�bM}:��5���ǥ�{��#H�"l%v^�L)ɚ�� E$����}��v�J�ٱ$�K��"�&��]��)l<��O{��P�R��8�w�;W��N|����{�ߴS�L��8T��Q�_�2�b�������O��}_f�it�/pq^�(Tk������w������H+Q鈔{=�릵�̊��2\S��2'݁�v��R�pN�v[L�+o'*U\{~��/����斬�0�;@���WYRd������N~�&.S�}���ŇL�6~���T�r��m��]��@m��gD(�SGe�	�sAn�6�DH'������G�L���j��l�齶
B��;N}�:8��ʱ�:�>�r#e7m�>�;Oz(�읣~�*���d!#i�~r�k
B�ֹ�Ӿ�M\���p�k���??�9�Բ8�J	{!�������K�`S$u6f���\��u�Zm����R>�p�N2��j-촙�ѠtC��)Y[2��OΧ��E;�R�R� qU[:��|覕��NI�������޽E���B�=Ua?Ě12i������O}�ox������V�,NSr��{���գTFq���S����3T��
#��7�x�=�Z�S���S�����վ檦��%�wģ�L��ʾټ��̧��7�`�    N��C\�t�s��G����ju���v�����c8����8R�lE�bgY��ö����h'
�#�qC�[�Qy"!�읳�$O�ʧx�������XGF%l(JO�`
�!��ׇ��Y�q�r6᚝��<�r����!�F��:���X����.���_t�JuϩV�P��8�E�%�xTN�袝�sRа�����M�?'wJQYq��r�G����K�Om�6�Huz	��do�X��}x��)]��a�*|n��2�d��F[�
~?7o�i���>W�D�W�Zn0YDP�F��j3����eN����Qr��c�&$�	��M�)sS�!�}�����vZ�0�X����l�$ħ�VG��7�q�/����4��}/h�Q��q�ފf�Sk���;p�(��kjf��y��y�jfi�9��n�O8�Ž����.´�9��+Ԑ:������_���s�G���'��W���pM֖���s����igo���ښطQ'��[kR�z�����{t�N��X�C���s�G�qt����g�Os7q.N'�.v$��^db�rX��{S�8׉��&΅8T;N�"�>�)�TʌP����9��ܴs�+ժ��j��},3m�M�P�ͳw�W����l�\�0�K�>%$�Ց��\��^ԽZ%����q��W�,���xW��I����=��Žח���u1�yJof��Д�x}��N<Qq�Z���"���6��
�(�
W��ƹNs7�|�$6d���?�����Ϟ�?�;d�ΧeV���%O���LJ�D�uel~E9��M��ik�����t���u!�R�MϾ������ZM\��_��y]P�O���}Ty���Io�&�5�-э�T�C��h�n�Ǳ"��������M�k���d2����ҩ{eC�^Q��N{�7�z��6��(�Q��;�R��a�]�{���]ďVMV�@�I�����s�Y[��]���r�'_�3��)ZM���癙SH޽�6��ͩ�����w�À?GȧJ}�*�ǵr|����UN��v��g�(Ck��^G��9�U�=�[��O�h��U��������"�-*�{���O�f�H_ڃ���*O�1�<�,c�_5�Qkf>ٳ	�쬎�.�� �+v�MފqՂ:Tg*�Ώ~��?������;�=�:��s�m&�Lu�)�(�j����v.�n&g��Q���H*��bA���,>n;?��w��O��f�)��ޔ��L�i��R���,��i<����T�
�K�+'�9J76��G�D>U�����YԩC�?��^�C>=.}�u����a�G<�k��YRAv�� p�pN�e�Id���s�����=��s�>��:n9��ST*�-C�{�k����~ģ�v"g_���xR�#P�I����������G�턋LÑ��s���m/GjF��8���;����yk��2z�|^�����#�3	�k�n�����)]��EQ�`�b��r>��j��Iy��N8�E���S?�"���<��b|�Mƌa�ݟ?���?r�fxMOrM�]�1uU���!��d�'<l".��t���3K�t��$�����7w�K��s![�Tk��kRq�j.��ZD���~�G�yګ�Wekg2C�#��;�,��B���_�M<��2Ē%�M��d��ތig�\=��sw�9���i��'zw�G�H=s@�Pۍ�'�^�����=)d��%u��N�fV�Q�%�^�?��޴�vEJTP`K���M�(HFzs�r������o�\�q�c�����j]l����5��ǝx_o��U+�Q:j級G}�j58��<��6����_�;��F���(����j(�?k��b�~ߣ��t��#�R�DR�m���G���'�ϺҚ1!*=�p';o�\�v�MV�3E�|�:ٺؒ�<��Ŀt��κ��I&H���Z)��8z�}v�˜�n�\Q����>m��)H�Qs�a�'�tuOj�#N�D6؉�i�5SW�}-{>$���o�i�[�-���:��+���r)=پ��N~�^O��g�:EݑQė@��f5�M}���L��s
���"�ro®��^�-�3��gz�����eH� D^���;�v�N�}�N��7��ZK�8ʶ��Q��O����9�]/>��Ĺ��U���S�B��G"�&�p]�{O��w���b�ݍ���,�s�h���+^���w�u�M<nJ)Y�I�:��π�}�1C���{^QNs7y�d���H\Z�޵ss�/Ó�k��9ǒ�;��/�m��|�u�wEg�$N�H���7�;��/�Y&ް��mB?�y�j����Zڲ��ם������&|��'���|)g�]8c�l��v~����y��b��Q�+fQ�ET�i\�qҺ�9#<���?���?z�_[E�d'��Tꪆ�!9�4{��Ώ�����x�?��S���N���-T̳��yZ��џ�����'�(�]�w�#�9�x�ONE���|��y�����~���4��B���=}*��NAׂ��n��d�����7gUBi0��E�-ܾF�lꞤ�Ώ��];Qŭ�p�:���%�j�d�L��F7��?�����x��3��\����q�ʟ͛T`�����?�����x���*���s�͆�_�\�r�F.�����G���ڏ�^�s�Z��γ/��H5͎�Yf�/��x���ڏ�^�G�ʭ�xn�S�.�4W�Eދm�!�Zw�x�y��*뎨v���q�a�wunl}.9��o�^��u!���#TE����t>t�,z�2'���8�J},e����I�C�u�1������G-�@rm�N�y��4���
�Ҷ�T��;V蹵�|ɗ]�7��e�����s�Ns�W����m �sA3(L,�g.��4T��ȩ.���#�#y�h�(J�Jgj�C��ku[7���/s��A'��%Y��Z�+��k_K�S�u�'��"�a}��W"��<�ɍ�ԥsV��4q�˜���v�U8�O���X��e��z����SN�������ڜjf�����L���IH��u�'=���Q�y�Ph4Ϲ��f]0���]�n]u�N&\ܓ
���2L��ٺl]����za����guU�	hW
�y�!X2U��q����H$CP��G��t��o���	��2o��io�*��]�
����V�RDn��c�:���N{(7��&r�%H��r&k�I[�k�����\�X��'�q�G�y����:E�P8Q���<�ܴs�<��j$�"�p��G#۔��(}����en���K�ޠ��D-or�/��榝��������L����M�c�Y5S"*�$$�*mĶ�*O��M��D�Y�qI=�sM�|�Ru���|޸�IW�"��:�$Mȓ�.g.&��H���xt�N��E;���3�Y��[#?�.?��k=�ƏN��E�({Y�P4����Le�jRɶ{J��<O<'7�����Ў|i$���H�(���b��������M��{�Ro�R�#"���i�z|�v�6����m������㡷�?�uo8ҍ�y�L�%�{Jvi�%�{��}�x��L����g�62�BMx��>}�p2���K�f�ZCj�sk��"Oi S�oZ��Pt�M�C���{��w����2���U�8�$��*����C�;|��/ͱ,�Rל	��:."+�fى��J�uC�;|�����W�$|�9�_���������.0�<���7���R݁��#���O��Re��r�}�p�{�o���|��"�q=�&��f�t�\�c��v���?����϶�F����U�J�׉���>{�)�|���??b�V�4:7��=�.�����+8m{�,�|����'X7�Q���P%��E����/��ߝ��7���{�}g]"Qa]�Z�!s6�܊,��)��|0�w?��r�sj��U��}Æ��lV���Df%�+�,~�����+uGa��P�o�`�x�W�IM�v��	��	��t܆�g(d��HFZ�Z�.����s��Ϻ��C�<�J<�kr��DpD��5�Y1~-�ƴV���<n�����    �+�R�=FT3�^� ;�	\�ց�3��T�4A�Rw�y�{ԫ-�Yֽ�Y,���J���.z�q�����c�_��z%��d�u�G �QA�Nu����o�c�_��zg���4|51h~��.M��2�۫�8��W���Rw�������� �+�KM%�t��?���v�:
x$�.��o�5�5zК������<�ү���;}�n瀋��	?�2�/s 	��=�m�Z=��~ݟ��ُCI�ȟ<��-�-0�y$�cT���;���v��b-4�\p^���}�NGg�i&��Y&|����9�Cf侶�Jo��N��@��F�{'���h�-�mH�����;C	��g�ۯE*�픏�������+vNZ2�҈G��?Q*��-���G�����o�y�}�$k�MK�(�>l���*N��E����s=&�e��C��6G%C5��y�"P�6���uX������{�������,�Qjwq���*�(�J�C�$.�Ʉ��%��K�A�"
Ռ�S,W���5�2m.���?�����?�����k��T�8�8���f!��#n�����y�x4l���EY�9�MTE���`���|)������<�J>�Jj�T�"������`O<�|)��{�澿����놐e- ���etQ7�[rR���O~�o�z�s�)�w�/1U�uxA}�k@����|�G��sz�;|�H����?�DK�SO�⺷�4v&��'ߵs�H��a�'��=���=�ܭ�-�o&�a��u��<��=��35.��F�J$�5ۘ�
i<v~�������;sA5�J�Lޭ�=�Qt�4�l���<$}�C�����W��
�<�V� �'�	7�c��T��K���䝾bH���� %�����bgK��P����L�?z��V�2S΃�A��Ռ�W7���S8ׯ���3������
��Bq�Qj@Z�(���-�릝�����9@�nS}Aj���lA8�|�s�;�h.|�هK�����������B����k��C��iQ�I/	���.����6��B���	9�\�'��#�FJx�&�#_��/��}\w�4���b9�\�'����Z-�ݖ�}mWMna�e)�ƻ�{�KN8�7x���Y*r���H�ȝ'��:|�Q�l~Z|
�&�7x��Sw���鐇p>d!����d}�Nͳ�<�H����%���c ��ض�*��k�*�|��7��'���o�q�#�[�LG?�79�a�B���� ;��]K}�[�x�����|��l%�Ʊ���=�{�E��F}�b�DR4*+INMi�Q�������}ś8W��Z�#�^�M���yZU����ѽ=�2�#�YQq��:b>q�p"������G��w�w����s���|ѱ3¥.�6؁R��p����y��^d-��̑���d��5U�Q1�.O~�����2~i���7��H�tzR�ψ�m���p�AV�D
_y�|�ԩ'��´eI��"�ϛv�Q��k�ډ�.*ş�\n%�*V�Əx�M\&�lQ�%c#�������n�f+q�2'��&�U�,:��3��}�4*7��!2�����*΅�xŁ<�b��9y�<�6*L�����y?ш@�L_����>�$�s3̬��;�	��������Շ��<8'@��V���j'���z�{�Ĺ��Z
j�[^}D�I9n�ž|�jR=�o�YVw!G�КG��a\ͭ!Vհ���s�������W��
sQ�A�b*�z�u }*_���n�;�';/�>Jlx���3'J�K���"k���D;��}���?�[��(�	��*���ŗ���(��ξm�|�?�_���<�CV��q�?k��z.(n���<����&�Rc����"nX�m
��y���>�C�ډR�{m�OF��J���Q��֜�m}�<��E����Evɿ�G05������=��a��</ڹBo�^�p�B��TGr��R$����<?q�Wރ?��}"uK�=�t�RR:3��y���m��/�ĵ=�g���ȥA�Mg�e��%%����yH'��"����{5>��'���0�lk�se��O9��m��F���>��{G�\)yZ$Pv�������<�ξ��@Z��{��5��:��Ͼy�c<�yqN �2����?�3�:M@pG_۬���~�Ε�m!��'7��:ܣZ$�5l�������ڣ���Q�"ܯ\KY����g�~�N���P%Rc��%���IZ����9�Ӽ�E;+��Fj0d�����I=)��9i���?�;'`�jg��)W�qi�6[7JѲ������9�Ƈ�[�f�s����I]](�Js{�!����<�a�����[�2���2�g�Ź��yNR8���y�R�L���!�Μ�1��]um��.>���u[�<�J]���>a'b;yc&�OT�%���,'���p�_��?z��\��S4ޖL^b�N���K�ؗn��׾ig�H��oF�*5[�Z�G�R��ǹ�w=�ڿ��<�����^A��g'l�hZ�eM�i,����>���O�YT�X�K�+S77�ސ����o���?��s5����| �����ml�-3٢q�\��������j��4�W���7L�㠹�����_�L<��Q��q?�U~�u�9T!ц�q�C�&����4){.yToJupS��:G�.�|�w�,��m4������d��l�nJ����y֐[��v�d���M���G��������o�Eo&�lg�s��31ZA(�޷g���^�a��9&H��QG��5�=��j�c�K:�qqX�}""�m�YYY8������*m��s�w�MTer>��R��V���j����?��w�\=H��1#s�}؆<��\*)�h�H��?����P�[C�8pGݱ���q5e�w����<o��v6��nu���" ����m|�_��I]�ske�/U\�:P$�DW��c�i�#̸2�cέ�T2���o�u[���y5��޼k'�ф��u��&ߚ��x|E�r�=:�?o�#��,QMD�Ťf(���/ғ�s㆟|w������DĢ!կ����X�zn;O��E;Wm	�:���9U��kA����<$��7�zؓ����(���*�O&S�@&:�g�n�PO�y���_��M6�M$��")�nWSܪ�k��n�瘨�P`��^O$��_�,kG�
���ԟ���g��Ϝ��{���Ka�Q�K���G�{�N�i���̽� OZ��\�}�����=hUREv�ɟ<��O�|�n)R��`���o�3 H�.8��56�w ���J3��������kg��|���d<�P��a��RZn�=�|:ϋ{�#���&�yul�u��ZK](<R��`�l�5;�i���;Ox|?�o��c�~��i�����f�e����t��J"h�5;��vO{�7�C��Wa��|��;���<;y%d]q�]��8wѸx��SJH�ѵ*��ʞg8��p�֮���pӸR!cg��p���y��}sO?�#L8�R"��%�2&;�B�7�v��󦝅t�����@)lj��v�*umw)~�wܵS����n�H��a��3��"�w�"��(����s�.	��u�ZZ�ȓy���:���}�Ӽ�E;{�9�:G(⾌�{>ģ���dS:��z6᚝%�ѓ�=g�(5��քe����ֱ�<��7y�K:#�5�aQe���L�=#nTwѩ-��x6᚝����v��w�̓gK��-*<}���׾�m7_�w���⣱swT"��Pw�.z�;�ٟȋP-����_��b���g�d��}�S��b���:����cI�7�!r�&W�u�g>�y��%�:'y����ij�äI�������'��];3j��p$�r'�j�'j6ՙFy��?�˝Q3ZI�%�\[��*�5VB$zx�N�ϋv�ֶ9&���>e s��t%�l�Zw���1���Gn4M���/k3�Z[�)ͧ���=ӻ��ه�w�!Iy�$�kCʧ��>C>�q�;��yM�<�    ����6'&�/��s�?u�i.�b��b*�AMi[7�����n��u��Dw�{ߜK�P�ɄɺC�'7�&Ƣ@*�&��;��W�kgw;V
�b�Ģ���VMA�Y2�>�ΓOs��ϙlW�@&�y���y�ˌ��l�v�0F=�y1�K�Ǥ䉚��U��Ȅ�U��j�:�s�����IFC�����L��!f�^G������>�M^8�!���tN����d\-�\����>�~���C2�;@�p�K�f���J�ؼp�t����`�L��A~o�xD��5���hn{.��{�,�L��LK>�F���$��]A^���}�Aߝ��3��wkG��-15Mo��6�ާP_;��tF�τ�s�i����(T����j�|�H=�}�?�s��(G.td��.)G�L���[qN }�C��QW�2ɶU�z��b���i2e��<���|��C���υ�K�K¹_���w��e U��I~�O�K��D�5ǒc�u��$�^F}�9�^�+��G}���_�����x��|���d�u��u������ޞvƓ	牊o�3�bk�T��H���ɧ���Z7��l;?�����я�^���Ujt3;.��ZL��q��}t������������K�%���$��D�4�Aq�}sn������D���x蝽�f'��%���fԍƯ���dC�:M�co"��?<��=R7�8�)܏��C&�c.zX���?�&��Ꮗ^�K�#��i|I��#T���:q�N+�{�؛���?z���mg�;qEIJ����>qa���y5�G<��כ?zg>d�Pj&ԃ&h�;�Nc�-�Ԟ���G�w|��Co�D���d� "_����dȭ6��٭���W<��C��9����m��n�:U//�ug���=�L��ϿT�׼-��I�Xi~���ڀ�~��ϧC<��.���+��Cp�R(�z�«>�2:}����|���~�7<�_ZQbe�vP�'oZR\+�[�=�kx�<ģ_����cW���a����.����G�/=ōs�o�\:"�K}�b��Q���2d �*�";���g�q�B�Aa1��c�4�#Ѡ��i.Ϝ�|�޵s����ԙ/U��1�{��h�g�/�p��x\�J(���';He�M�R����ˁ*���\dS-��L�!ԹӀ��fX2���:�p�N�r'5��yɍ4/ʇ���g����]�kV)~�G!r�7?DzWۜ���<����Zny-�z���D+뎼�8���i<��i��&]u��K��qKŻ�1�YP�/�I�����E;��0��a�(��u5�S�;��g���jp�gO�%�_�7ov�&"_���'���M|���)(�A |��LL�p?G`�Y�-o���xy~�k�B���qsX�e�.N��>4�ͯx�n�Q��gLf��4\�|]4)��O�~��p��x�\n�Bg4z�ɋ��(�M��1U����O�׻s�-G�a��=^�X�t�GŤT���#~��<���s�î�z^�ufIE|&��3;�"BҞ��܋����� ���n�'��Mm����p0��|rL��HOf��H�#(4):Q�M�><�QN�Wq��JVT�T����h�edʒ���N{R7q��26�y����\��1��G��<��E\{jp��,g�CN~��}&e������U����-&"�q�%�)�������<�{_���$ݦa,��vR_Bm��[	����2)�����t���8��S��p�N�����P��.�7/Gr'���=��/y�W8�D>��}�njfR�|@�������ŵ�(�
������rr�����y�N:b�\v�xģhYmaҊ����e%�}����}׎$I�v��ŕ��=S���.ڞ���Gwqm]Yc@
�p�9��n��JX(<��;K������3���2���wT�LOM�17�����v��QU�5nn]���p�/��S��"(m;����q/��V�:�=����=�d��ز��v�_��?z%�^������!u��6��
�iCz��t���7���~o(-��;]\%��"�]Qw(��m�����op�R��S�(*��]�Kә��_u�bj��e�Ʉ��4���ӝ�:؟W7������rm>�|���7��'���۱&�������}�<�:�e��|���7��i�z�j�7柨��ʥ�Fۏ^so����o�#�N<�uυ#��K!P9���tU��HH��a�!�o��I7p5�(�i����%�?���$8���}�ϽȻ8�tur�������f46͖u��c�i��"�_�Z�xR��57S9'0�}���X��yYG�Qxs�h*<'�fm�ƃs}�w�Ź̄K�w���3Tv��M}��m��O]���QU��*[W���sq<��E��:wjOx�M��(3�L?Ew;�{C}�|IWH}���g�y���i�,��}fA�1�P5-��[���]�i��uH��%x��}�o�ւ�<f|�<��ď�/�=�����=vgJ�U׉�:v��W�2.�� �q�<�Gp1"ON�����=������Q���ｑwk�5SlD�����Ͻݻ�j6�K-Fۤ�GZҒX����C��q�2����l�j���Ygd�Ƣ\d�#/��]���7uFj�0��&A�a�i-�W�r}xyx$�1�L�ٲ�ދ��M�ٛ�2�Ѐdd�>�g�tG��V)��}��9S�õ*=����}�'�����:�w�Y��^��Nh3����X��[K1����C�G�a=P������<�6��������
6L��bF���of����(�Ϲ�r���>�L[}˨;�|ξ�	{57�ò���g^���x�|~��`��?ɳ�r>�9���Ee��O�q����˦SM]�JbྯJ����Γ�'O�e���O�Pp��R��d�1޼�*��6}����{+(؄7U;�A"n�nF�Ѯ��ڼp�~�k��k�B�j��(RO�
YC��/�����>��]���`!7�zg�rr�G^�5�}�|���o���%�g���E�f�🙟��!� o����П����K������?B@"_%��:[Q�/O�П����;�R���Q���%�RP·d�Q/DBB{/2���~rxIAz�3�>Xd^k�$�N�|x�<���7�����.�ӓ]
�t��M�A�Yf�s���Ʉo���%|s��r(&RrU$���x�p�� �J��}�r�χo���-�wg3�L���
�7e
�,|�p��~�y�χo����w$Q*���vߦ�h�ǭ��m\�����^�ۍ�DJ�@��J3*y��5��ʡ?/��Oy�R�r�|F��vD��j�&r�X���o�C<�����W�ω��! ոܟ<�&�m�����{9�#�7��� ���E��;f"�ČFsDIb#���ѯ����/�1�+���#�bK}C8�ꑜ�G���|���<�ٵ��H�Y��T*i͒o�-_�އ-�x$��yy����KL�C[�t6M�R�w�'˳�9os��`���%ꪏ*���uFWC��ѽ:�w��~<�N�S���0�/�H�3ij	u��4�?��';/�\Zq���#n6+�˗T����%��P.��쒵E��#��%�Y��������'.�q�A��T� .	�}�:��j�:b�<�w��0��bYw8�J�����bS|p��;���:M1r�����#�^Ƀ"H�'�,�Χ��e���P�e�s�|R�/V�dL]=�D�ӗ9�\��\�@Tk!?�t!u2���ۤ.s�׾i�]7%���x��+��Q\�0r)9����\�M��z���j�W��YS��Mܦo��䤧y�8W����2�����0����F���8��ϛ:	h�KB��>u�+ꎦ�Kchz�TO}�x�k�d�΄�9�@]��ץ09�Pڣ;��O{�ή�OG79��8��ݺ�9��{R�g����&6n����'D��7��g����Ԩi�z���OZ�V�B�RҪs����>�u���9F��/n�Q铟%���\[��s��������j����/    ���C� �����]�;K�#��$�*�T��N�d�yUn����.��w#r1+(��D�]��ߎ&�˃k�M�fgCB,�#_Z�n�뮙9DKmk��6�����}]��nt���H�G�	���^B����:����v��,�W�K�n5fQ7��&��P	O0��9�N���z�1�O����N�M;5�������e)�w6lI�~_�����\�M�]�뵶bHcG�9L�RBmuSK��z3���o��̈́L��/n�}�Q!��f�Y]��E�m����us�/�e7��%�s@r���Z��^g�}�yw�a/��Y���ؐS�,�͓?8�f��b){N�#��;'�H��
�ا%ea㰿km�9p���9����4H���E�E����u��\�M7oL
y��9�`�%a"�~ƣ�x�D�R�/Y-�2��_��V�78���[|��[�X�?#��[��� �C`�7�o�奾M�(�%�K垩�j2���/\�J1�y��<N�ɓ}����&>�W����a�j��V������7x���'7ܕ���E��ɮ%�/K�J�k�y��<N_�����f�Y�Z�P�c�ޡ@ʳ��~�<����/�+"䌂|iΥ[A�4}4�Py@�>l��P����%�&��9M�H�^$.��ӫ�Ng�vpC��ӗ�<��>ȔXo���..�Ȅ�	�����͞�[{�)��4�(�z��*:���\���)��d���鏇^��.6-^M��?���0dFk#�V|�o��*oa���QoR��_Lp+F;k�[�A>u���G()gev�,u�����̌l����읝��n�\�;�z���l\�Ȍ�X3�|l��|�e��G�G��`5M�#� �,Ķg?��\j�+�qA�:8W�E�G�"yN�)��_��\��W�Iߑᵉri���s��?���	G��j�L�a�po�/55�5C�n;?u���ǕAFj���I����D$��Y���y�N'B'�A�|'V���Z�U�-�?���^�M����@~��>����Q�W�,���O֓���=�04Ԅ�]��Y.�Sx�m�I*��y�4�켈&\��mȊ�C}�=>_�t�';�/��LO{=7�뛟�p�z�ȗ
ry$���[9ɞ8��\�WC��øZ�����Q�4������'�����)z�8��W���>mppaKo<��s7DJ����y��MA	gt��){��s_���vog��n]�QPoG%T(�Cxt��j��Ǎ������ޡ~w8^�5��R�|>���yg����c5,�ST`��p�p���}Ëvr��S8��e�B|��Ս��6������E<.Nu[��@~��T���9����#>z��X�}��7a0����[���nq����'���>����j��t��dܨn>�P�����wq��J��%��|A�ОK�c�w����'���x��w�}�<'�?'2�u��D�t���7.s��_�e�\;����"]����W:k���ل{v�Ho=�$����8�����O�z�'<�".SD��������:�p���ꐒ��߻��vo�@j�%�NJ�l�Ǝ�u}p���Uw���k?��C��3X-������C��Qɖ>�'���G�}�_�?z�����p��}�M�o�8�L���}��N&|���g������g�vR��X[(���Yv������D*CV��ӯ��W*�8�I��T7.�>p��cz��g��Q�����uq6e$5i%����y~�\����|rT�$v�����?Z�x��>J�C�}w8W����x�?�Eb��{�-���R6��3-i̔�{�s�ot�[~�Õ�0,�;��8B]g���|/������8W�F�1���k5[��ۇ�%GH�\�D��lq�G8W�F�0�5�[d�Tۀ_��a��Ԛ�z�+�9��C��ݺ��՚�<�ha}�,�<.S�
\���ٓ:�y?B���O(�?���i� w�|n���ܼ�^��v����%ǣ�ĖE��"@��m|�x��u�j[��&��q�����x
*��˞��Ϻ�.ށ�6hC�i�;�Ŕ��ǒ�FT��NzR7q��D��a�_��j�p�˦�ڴyO�y�	�U%��-y$J���,�c�3�����]}��W�<Ե\��r�=WW8�ݫ���E��ڻV���O^�Po�\3 �_�x�Ol\�l�5;c��!�)���>-u�9)�d�Cִu���ru����	�Ɯ����2��~�Tx{͛��4�~?�Ӻ?ij�����I�_e�ĿL{�R?�v��Ǖ�mmpI3ro�*�����T)s�y����o�G��T��&��B:��d����[ld�Gg�٩q�R8�����9�#�:�������<�]�5��7�MK�K�����,�޻�Tʃ˜�⋸��b�K�(o�yy%([ӣc?�/�2H�Vp��ROJ����P$q�������wt�5�y� CvSX�$��U$�k�}�Ͼ�e�����H�ֹˆ��&�t_��ɗ�t�n�� ����snm9�#���\���!�	纪w&ٓ�R��ò?�:�^��sn<�S���>,�M�����r���n��K���|�N�r���tv���w.�R��1
\�����s^�.~�����8�!�J�l·��c�α�����|?���6�%�E&n��[��\D�9u��3�������9�N���x��a%��#�M!����:�.~�CJ�ń�<炪)���2�'�M��gw?B>?�e�F��K�|
���M��R7oav�L�=���+��ihD�騇2��ȡ�<%�-�=��>p��{��W�g�!�u.�ޮ-���d$Qm�Yc�s��`¯���C��?%��/n~~P�^W3�M"������L�}���C����8�j율���Gܻ�X��ʢ�gw��$���9�!3y��:�X�!��.dU
l�D#EҌ�Q�ո$pY�����̯x�������,���Ũ��lɉS���u�_�.>�?\�E ��Zk����8�[����·�̯������,�$2�w�wlym�R��le�o�·�̯�����6��`6Ne]��|���������|�˼��˧ps�:(°�WT���"\+�mgo�/�·��=�|���{��&�$��!�d�!��EWr�~ϝ�<z�ǗO�e\):'�Oe�0zN�)uB}A�$k�k.�?��=�|jN*N?:YT�N������E��C;�#��9���˴=-�S٭�k�T۲f�;%dqm��=�����g/��JA�L�~��4�����?�'_�w������Q�p�K쟟v�ߦ����!�kN���?��,��hVM�|�N�}R�t���E�ݟ�y���:�"�R���@2�$���sR��Զ��{2��G8�kL[I���i�2�Z��j,
�,{N_��u[?
>�@	[��z�ϫ"���s�Z���<���e]�K.PXdq.2e>�H���Wni���2O�Fi� .�BR'��X���Ѥr����fxz��K��Z]y�'��d�#<�݊�����]o�o�\�:ED�J�!-dSj���rMk��&��ݿ�s��}ծ��J��F+2yN�Pbl�������u��R0b"�%�8$����]��S���|z��������铭w榑�z�Qf��Ӿ�a�(#�މY[�֓��R1��!+�m��-|���C~�1�ƎE�%;��xH�Z�3��I�ޓ��}����M���N����[�'a!�s(w>�}�J�d\'�Q"?3y��H��������������L���O�܄ ^�-���>�My]�3?�;��}��A�2�q�|���$! ����9�?�[=�4l\r��8����txV7�U�Ч:���O�a��3�Q&O�r��!^]KT��|kOu�?�[�Z�"��5QwU���ʁ4 ��9��x�o��*�j���o��
r�餤�Ӷ�v>����G�B��B��:�Q��"�9~/]|kO�p9/3�Jnޝ�8�*���I������f������̜΍�pj�kδ4\+���<j�u�{����鐻;�@�    "N�E]x|ܥ�ZW�;��w���e��Z_��.3=�M�+u��nR�v�㐿�3P�r�N���oR��Rv����9���?� ���n�S�F�?�|�L���)\�s�t�3�^��|k�~���;���^�xdH0+��F��c��荚v�w����S����&<����7��0�03��,��{n"<ԏ��z�?s>�+�����|�n��g�oU�Tn��P?�o����G���@��y�,ȏ��Ư8y�|��ǫ�ϧs������Egޓɑ����0���"o�QJ���ű�v�~���EG��L͖�!�s�L�kޓ����d�k;Ã	�׹~�����m��I;-���t�jMr����v:>#!MG Oȅ}ג�!�@
ѕ^ǶSL���,:������̐B^�L��(�<���"��L&�^7�Yt�W�6���}'���f7�X�t���:��9��;ރ �q��b���$�{O3�j�-�����/��h%&O�Y�X}�ǟf�޲N$�q�GO���e�n��`��4ճ]���4X���{?�3�����M&�f)��$�&�="�[�crK�89<�q�Gݴ�Z�m�3-m.��D��1w�@x�x�_�O���?�Qmu���0%e7坟����%<�]��Χt���v�H�k�n�\��׺r�?$<�]�7�|8�ϰ<��L��CH�Uz�f�]��U6�Ax�x��O�'[�fje~�*)t�m�A��bC�򣇾�����.pCrd�$IwLdQyr5��5gQ�����dx��.0���[5y��ϥ��*��)����m�C�B8����^�r�x���o��`r�bmM��v>�q�M����L!X5�z��pn7�[�q6������ǽ�Χ�7G%ݣ���������b�Ss�Ƈ<�.p>�����h��]\?��Ar�%����7���������[ ����͛=���py�Y��������ͧ�v}_�~��\9�Om����A�����C�������v�ȭ���M�]�p��#`J�G��Kx�B�!�q�u�=��bu�G��Nqj���^v>���|L���kaSD����Ƭ�(&�!�~Ey2�M\wHǡ"��Y��>x>�7V��� v�Oy�����>B�-�VK�{�v���ݮ$9��=��>B>���Hn <B��F1�m�Φ�˶�i��^�#�c�M|bk�L�<'y1�W��U{2����G_��~�;��_��d�[��6p�+ԕ���k���?X>�w�@"�L�Fv�M�1�A1����~^��?X>�C^��͙`�G��P�޻Y9w�``�yã�w���[k9s?���	��p35��ڌLn�yã�{�cё��W�WhF��O��(��Sb蚜�v���*��F�5d�e�J}�b(8���99���Qz2��}/��>��/�}FR�s�����\Avt���G��U9�gU�-ȌH~)�
-��D]��5w�nxT���Ss|��jq}"L����,�JwI�����ʛ9�rj���4s�l��#���Li��2���2�𨼙�+�tBg��qӓ�D��xKE�s� �<.����_���Lr:-vv�FJw4v~kT_t�=��nxT��Ǖc�q�I��u~Q�s�.�}>��m��g
;���|\9�gڒh
YQXW�g5����)���})=�ы��r�oͩ�% ��[��O�G��,G���9��G��>��_r�+Q���'Zcm�V񉌶�=�O&��K��Bƕ�,ֱ��q�I~{�� ׏��.�}�ȝ8�_���۵d4�f�	ԟ�2��Χ��_�	��p�w�[�#��|_��kDj��GO��X�
��-�Մ:��Iğ��^48AP������/�$�:���fG�J>ޔ!~�N���?�C��b.����ن�(p6�R'u9�sN�c����/��*�����IҀcw��+B��	�HX[����ҋ>�r��ʥ�uv��N}._9�N~Y� ��x>?�K/��ʩ>+�C�{�:��Q��w_Y����C�C���Ϫ�곪ō��=}���N��h�0g^E��7�C���Ϫ�곲v�\�<���!�vl���E�՝�x)���áy��%��G29��-�0��a�+���ҋ:l9U��Ekh3�2^��e��~�+ �2N鮿�x�E���î8òy��q���nV#a��� =�=*O&���갃���g-�.J���Ȕ|m����k�~T��E}���o�,�Y���� �G����p$������7�g8Δ�_eg��m��f��(ˆ��	;��E}���oJ�^�GB�����ʺ!�h�(�����G��}�g�;�`�9{38
)Z^W��Z�xQ���6��^�˩�!0g��������E��X;��h���G�n�3�٣ֱk~�I��_쪁i���{]����^��ʩz�k:�E��
���CZk	�;g�c�՗^��E=������2�L`X��_IO�h����v>�ыz\9U�k,��.fd����5� �e-8کO&|�s�Su�����S(���Ls�r�9��5�շ�����~-:����c�9�K���s5�6�)a���w��`���y-:ӗ�ֈ�R�?����C�@�QK�n���xD��!ע#��mh��-y5����dk���-y���G4�����_�˧��R�Q͉��b���3 `��{��G4����;�Xke�ʪ�3ͤZK|i�(�D|����Ľ�^���!$�p�(�h��I�Iz@D��-ܠm�xD���kљw��}F^,��G��{ğ��8�h���/ф����Kw=������<q�)P�1�M�����G4��}w�ꆋ5t�+���G��bף׋~^�	��;�#���D'�X�;�x(a=�ˡ\v��Ƚ�^����{?���A־�㶾L�"�#�Gv��Ƚ�ռ�y+I��`�:BW���ǀ(���Y�����{Q7��#���[�u��u�p�9�Q-'��K������ע#�3X �r�N�i�
�<?'½C9�;ox�^��Eg�w+����s����x	~~貱W�%��a�}��]����k��
!��-0�eW����x��w-:�"2�����w� �i�.l&8�\6�I���m��ٱ�D���qV໛�ݧх�qu���^7���%#��&�;�mJ��J��������.s-:r>+@�5�v�ܮGB=�	��R4���Lx��!�|Ę������DP���v$��n������ע3������2��ek�|nP�[n?ӵ�	_�?�EG�b�A�
7�|�kZqr��O7b/����>wv-:r>���S4�Q���N?_٦^f�nI���n~�#\��ԵìI��y$R`�g1l-6kvM������p-:�>?*)�a'�wɈ�*������cf���Mג&���CsRԸNv�]��u53d�����u>p���ѵ�L��(]3�%O��^ᗘ~"g������m�}���G��7u�|WpNE�þ5&�R�׾?�����kё���YBMğ���9�\�4͈������E^��^���ĕ�9��wA~���	h���m�/���i�w<�Sy� .�ЫJ8D2�!�h&�Ne�֓�q�ϟ&|��r�/h�\=Rbiu�b�C�i��������7>��7���m�q2��G�]�|Y�i!�̛�Eo|,0�E�)���0Ds}��F0��Y�7�p���\9M�~��T�j���-�<$���AFL:;�;��������҄7��P�j��-��p�����bBv��藝��ai�~�G�#,^Hإ{��!%n�ʆv+���/��a��΅�Y�#�/�����Cp7kb�U?��<�_ۉ�X��'�T+��ɈO����o��yX���zgЩ=��{D�w�#a�J�G�5��o��"i��xIν3`�{�����3E��&�w"�j����"���5�"����͋�T[<E����6��vV|�E"�R&?�ݵ�wŊ�~ċNo�4�{'��Cj�.Pw�.�ו�L%B���jԱ�io    �0��ȵ�����*^P���Z�sq�ǥ�Zle��m������ ]C�N����i�z˱�t��m�&���C���٠=d���;-�Y(jZc�y��缶�����Ϊ�9A��`_z ���FC�����·���v|K���е��8�@���s �\<z�;�	�����{�H���/�2�i,���]�k�{t��	o�C}��!�,�Zq�eϦ�n�UO͹�W�y���c;��#C2b�WYF3�ׅC���0$�8�6����s֔���z\,�s"h
�9���ܶ��"o�i��g�cWf�~� �XVX���٥l���ф7qݡ���X,h����3���22a&�in��m���,i�y�+�"�iK��Rm�6�w��<Mx��z�p;���2`l�Y��a��������u�.y�^,�|B��`�G�a%V�!��������!�i\��,@�#TR�`)��VĮ}>o��4�M�|����>Қ����H��j��S�)������n�ۙ-	��g��~��'�9!��a��m���[^�k_���8�O��R��X�'�I�Lg��K��烟�K;-� �@����A�5>�$�v\��7��?�s6\w�(i���E�:q��RȘ��G7r�ho�C�6�;nH� ɍBc��}�}�.1ի�Ro<�lgiޖ��ik�r ���M����9}��~�!��wڐWXf�Ɖ��耝16�4$���)�C;Ǌcv����p�(�l�rE�N[�����?��=y���j&)"�{*�����\S�|�z���	o�C}V�i.|XPK��g�|�5p�As�v������YCq!�i��9��C]����O�h��V��Nu�O�����H�mm1���7��?�#D��z���@]`NH���yC_���z�~�G���$-������V�F:&D#.���7��xi���@uT.��=%�#>�LS��!dN{�\o��lg��Wxv�y����{ӳG����OUo�u�N;�'ma1�2���L�����v���w�w�?|��i��>A�F~����dtu���Ү{t�1�	op�P�J�,�nM����H��Q�z��>�����y�h�.�&�e'NsjfY[ I�!i��6q�_�+��l���� bFlW�h�������i���lvN���nJ��.�O� �)G�g���������;X��u�q����MJݑ{����y�����%�CnJ1GQh�/5>����>sk�������v��-�_�Ρd�E.����l�al<�ͿÄ��ע3�\8�)�Ik��2�H��.���{��o��4�_:���p���$̏����ОZ�����\�۹Ɣ�(��X���o��k���R��?o��4�M~t�O���=���N}�f��p�CaȺ갷y�?���2J��d��E�y��7��3p������Q8�G��2�Z�||���<���ڣ^�޷y���S�#u����'R�#S�|���9�}��kӄ7�y�?��"�L�� �h���99� ��}�X^�\����5l,�n�gH9��N��EJ�G��O~���ԋE�F�Rﮧy�R[�:;���|x���-����T����E�v"!��Z�:7�u>����9ka���nߒag��b|j�5�w��ܮ��K�S}�A�(:�kd�� ��;%�bh׶���x���Υ����S{e�ԓ���j�#�����Ɛ���<Ļ�B�C�0Ȼ[���Ŭ�x���˅G7~�?�s��J_�K>�}�T�YqJMmǟ7~0�����\�Ɛ����M"�|���,*��z�ߟ��?��k�a�2R����[pΌ�W���߽o�`lgI�f����W�6*u�"3���������yG��k�tT���b6��G|<�~��O��Y�u<%��V8�O��ܻ)�!R�>�u�O���BU��"y$X?B&_�G5�0[���ҝ��o�:�@�Ù|>�Z�S��#� 6�T.>+������S��D�j��᎛����1�P�\W^|���uע#�6Z{s�>�uc��a�(��]׾�r�m�E�"+C�|_*��ҧYk�>�A�|��o=�9��o�1?�μ�ڒkF�q�Dx�SEL��� �m�YL��/�,:�#�F�p�6p�Pq3ܔ��Nj+���~�K?���/�Fß-�7$�{kv�V�$+�ұ�O&���,:�ر�@ԙ-珄҆��Yj�3��L�.p�W��&��~��ާ�	."��y�B7\g�zR��_�j��U_�Zt$����礑���H:S�:���_��?��U��Y�O�y�Y4���d��w����n5M��~-:3���v�͢HltH��|G���Rsl��{�W��&|�׾��w�h)��b��D�u�OfU&�!l;�խ�	_���EG�m�q�'�/�q��9�k�+�(%�����G_���EG���U��h�d�ި_��
%s�������Ghg�R�#U��CA��rď��|G"�]������,:bgcg"B:�:h��j��,"�т+X�S�Lx����<��,��&�#6:yt������\��S��K��Ϣ#��-ہ;ƎJ;gC^�t%�y�Q6�}��Ytf��p������{	V�/��8D��/�l%�ʐ��خ�ю����w�:8u���G_��~��ʄ2H��X���4 �+�����wy��/s�?�����U�h���?dӞL��mԹ��<�ї>��EG�Qi��6��ゟ���߹�:bԹ��x���gё�9S�]ޝz����P�"��%W�$x�e�gљ����ф��_*H��d�o��[���v>���<�g�Eb��lR�(~��@	�(s�}O&|��Yt�WS쒱{����M+AM�7kVн�����/�,:�V��y�ٷF�D��]1��-����|��/�?���+����zG]�U/ֈE��Z㎓�}��Yt7�zdBaeֹZ5U�/8����׾?�ї>��EG�"}'�R�N��e�'������w����G�������cё��K^u�7�RoW�U�ի�{߷���I��_�?�s"��.�d�����	�^O����n��5!��^�μ'3{���U��4dG�6X������;�	���?��)��q�A=n?�O)�J���Ím��M��w�c�����̂Q^�wi�k���v�M�n&|��Xt�K����8���M���(.��}e]v���c��	��O�����Mj�ցGڣ�����g����/�����y����e<���>�p��Hc��Xc��a�ۏEG��j�$��A���Ǳ���u7�:���3�/:���̡��-����x>��\� 9*efm���yã��{�Ǣ#񧵮;�ɫ)>��E�WF�Y�^��G_�v?��3�_v�����;�y�ɸA$��:��yã/z����f�jG`�\#����O�-V�^d��Q����cѡwEW�R�,��\eF�L��FS��a�{����ݏEg�h5����Sr�t��u9��b���d��8��n��]�.�N1�헼k3��J��g~���z���.��E��<�+��x�'���aԍG��^����v��0|���v[�$/��;)D�}��_��EG�]��Fjo;u,�;��-��\���~͋?y��e�4�Zv��!�fR�I�����K��~͋?��7�8��x�h��e
�� ܌֮�7��<�5/�Xt&��݉R���	�f�P)�P$U��l��x�k^���LH�-�ile�U$oL<J�U�3������EG�|r �G���>��]M(�q�p`��Gx�+o�Ǣ#~����=�6_���%��,��m"MڸY�Lx�?�:�=/-F2�[&_F2�C�N]�V�n;������EG�O�#��KԋL�7%N��i�5�=*x�k�Ǣ#��0�����צ�v�n*��W�4ֵ�x��|�Ǣ#q]�T��&��:,2�y>�xg,=o�,x�k�Ǣ#v&ۛ����}�x��UK�<��KW�<�ѯ|����y�pD����"E~�(��<8\,�l�Y��Ż�1=�b    gk����9�8�g�F�<k�s�/�<�o�g<s>=2�P�����P�풤��D{���<�Uw�cљ�Ȅ[�	��Ĳ��l3ݷ�RF�C��x��f<��2}]�"JJ�w�HU�ͨ�=�,��/�	op3�Y���e��Q�u.�O�r�H@.:���<�U�cё}�b�e�DQ/q���Y2�D����x��N�Ǣ#~i>|,3��腝��s�C�S����<�7�S���പe���!2"SG���V�{VB��`��G���~,:�'�x߽	�<�@݁��I��!!װ�|�#y���P��1��M�u�9�o��G �B��v�x$o����I�!\4��HL����:�c��u�xݣ<�U�cё8َ���f&�'xk^٤7�g/#\���~Շ�Xt�+�σ"��w�,���8:�L�z�<�U�cљyX�]�kD�~��S�:[&r��<���}2���C�K���\���8kjt�L����$�/���������=�����A��g���r�H�R�o;ox�o�\z���j��DF H���F�-g܅��]�����G�{��Ǣ3��jՔ2�w%�Q ����������H����T=.������9����fװ�Ҭ}���������{�[g5�o��!��ӫ/��U
���@�`���SO�������[c'�j�i0�!	���I�g�y�#}S��c}�y��)\�/�i6M\ <Y������G������n�(ݓ%QgD"�屴F�f��{��H���T�PR�v�y�sa�.ǡ�!���}>ݓ	o�硺�u7��0�z(����z�VA�鷝x��n��t�g��ջ��#"i�qr�9��Jҽ���~�O�Xt$����Dp�3��ӔP9_ �+�R�}���M=U��+�p�čqr4�c0�	����m�������L��J[�MZ��K�]<�K��qf���x������2W�V3C#?m/�K0[���K]mn;��E�P����VZQ�Y��!�(HAM�Ȗ'�%w�!��^��X?myF�'�"P��׊��D�G�5���G/�z�n��(��)����%ytq�ƴ*��.��G/�z�nXg\#�{��%z����2���'���CuCͶ���8��!���1����X�Ɩ�_�x�+��Ǣ3}�9�:�:�P�q޳����-���x��n���#�^��E�|A�%��Q���Z�y������L\WF�>O����e�ap
Zl�!^�y���_�C>�:V������O>���G�_ȏö��^�7��)�<Q��Ď��1D�J�55gc����^�7�T}���+n�%�������=G�����ꩺa�:�Q��%{�t�G���/�3������E������\�{⦐� �lԖ�����7�����S}�6����*KSvT{�,��^\G�L;Ó	o��!����c��r#�	���R��{ ;�(�ɋÙ�x��H�.��Q��"^*��t-/�R	�/�<zQ��Su힫6E��|hQ���͜�l:��}���7�3қ(ae�&�*y� �;k&Iɣ�U��#<�ы�������:�5O
]DG��S�hi��7w}�<zQ�S���W��؍l^�CZ)��ktJ�e?�_
x�������qhה�l�	�T\�y�9Ww����<zQ�c�wo�{ e�TՖ@~�\�K-!��g�7��������T�p| a�kq>�9k��N8��q��|���w=U){�ͬH�Pz����nC��y76�'���C���HiQq�ʤ���I�	����"�ƣ��G/��z��.�m���x	��Q�}����k�{���������P҂uN9'e�p>�i�0���&>�ы��������u���������r��Ll;�H��y9T�ma��ɛ�8��D�|M	)g�6n�<z�'����c�RA���7"�,�Ѩi௭�;��E�]O��{]2��2���K��؛�\����?/���qC�vH��ɕO��
.#Ζj\;��x��������ҌS�hЫ��	�l���\ͦ���G��Ǣ#�!eŴ
�|��<L�E�|bj=4��'��!��ـ�}�fr#�%[�2�ϝ���܎C�_<�_x�>���ާ�<�▱�l��{�YZf����_<�_x�>�G�F�t)�����H�?�����7}X��'�cљ�y]��8����ؙ2G��Q��:�����k���һ&�\=\<f-wo쪾��C(�n����Ǣ#q����8dr�c0=�������27~����cё8dfA�Q����yǾ5uf �\�0]��_<�_�X>�?}�B(��]1)��2�r����\�����|,:S׎ݵ�|h�x9ʬb��+�ɮ�>�����?�s�ȹwnd������>��d�N��g��3Є7��P��kjm	u�A�������VQ�m��?L�^G�����avx�8�� ��Rj��I�������&���C��+� Rw�S20Q�dr<�L[�d����h��y�=��5��;�!�/m�Bk�O-��qՏn�4�k�y-:�x��5�B��G� I��g� �w�ك�x��]�Zt$��%���,���"5Z>��xzD+�9�r�g�	o���:	�,6�uG�R"SMk�$��hm������@��qע3u��,��Y�v$���7�!���z񍟁&���P�X�!!j>/�G�T7��#z�#��|>�����kё{�&>���|1�~�??a/����7~��f����G�y +��Iu��_\�Y3����Pn�4�_:�WA�&�u)2߄�Z}!ݢ����\y��3x�&/v���Q��Ǿ,_�8�_�dRƸd���sRn�4�_r����wRr'�@�:����,ӄ<���e��܋��kљ��׮�qz�����g�2q����3����;�K���k�ّdQE%���f�U�������&|q��*טZ+\R�w����i�''l����h}?�o��+V6��N�D$Z"�d����z���|,ע#��`Z�A7�ŜW25T]����ȍ�7~��"�s�򸑬,�S��y�l4r�+������o�4�;��H1s^��#�A�	?_�O�����v��Ƚ������*H�]d�#�"���������3����Kע#��c�4��M~�0�.�$W����;��3Є7~�P_�
�4ϻ��35H4�a�˹�]ܼ����@ޜ�S}Au�Px(yJ'nT���*�*HH��:׍�&�ȏܩ�(6�\�� �d@P�M�al  �>w�t�g�	o��P�@[����Cy2\1��/?/��r�g�	��w*��r���GT��hrl�ic�|��<�^���$��5-����|�7]]�i�5�D^��9�I�7z|���ZvX����4��{��"i���O����EG��M��=�I�W�W�kNI�n��z(�'�/���*�_��vϿS�/��ߊo0��q�����+�,:3��BeC]�F*�9ϱ>D�~����O<�_tB����7��n=u�YGX1��Fr�����H<�_t-��_���s������9	�kZ�8ڙL��k���H���V+;�|���S|ЪW�l]�����E��gё�٫��n٪+�O8�W�J��z������E��gё������a�|���߽�v���G��'����Ϣ#~~�ܶ^�$]������56|Ћ�??��ѵ�Yt�O��1�ܪ컠HB׿���Hn���<��W���̜~��y��d;X������F����}���Yt�Ȩږ�u.-�f��XH��o����G_�7����u|b�ŹH�p��ۖK�ߺW����K?���O�Q?��y��҃A�Q�{����Kx�k��Ǣ3�6U{w�B:3��K$�����#v��K�Ʉ7~�P��������rb
�y(�kq�{y��_�Eg��洞Ұ:��z���$�l
�p���<���c�?�$�6"���d����u
�x��yGy��_�q���3���4ƶ    �|_*��5�o;��׼�cё����3�#v�6i@$�\~���G��?��7l�3�<X�@<�u�v��a���G���,:�B~�
����u�A�PJ�H�r�Z;�,x�k������,E�H������bU��G|��=������E�椆OӚ ��`d�5�/���aSgʹ�|��_��?��hq��-���y��63��!�f�o�O&�����9 �$N$y��ԈC�%���������?�����M_G����:��uX��CFT��s�0���?������ʪǟ�â���ۯ��P�ں��>�ѯ���EG�?��)�w2����ި�h`��d3 ^�b�Ͼ_��9�?���Ǣ3},�k[߰q���By�U��=��i�g�ڏ	������;:�*f���I��@}�!d�h�Pv��e;��H�3kUzd�6�4���$���3?}����cљ>�<48o�"��&�ч���%��,��v���*K#�<�:������\J�Z�N=ձ�&��o��HݐC��IlN���+F�(���gE�s��O&������a}���=��a�L��ıIl^
ԓ���kg�����T���Z` �r��c����>���,:��j}R�L�O��f�:��m;������������D����,�笺,�;RtO&��|,:��݋RR| �̬���bϙ��÷m����-�Xt$�����f�ֱ��ުf��Y����}���1�|�cё��S�.#0������Dg�ړ��*o��޽�߼�y�N�@��2u�7�/2�	��E�]׾�ӄ�}��T\���W���ɓM��*kI�����N�ԋ�U��2�1���~oD$u�i�8�Wh׾�xݽ�W��E
2��/�g�{Fx*�r����o��4�{_�?�WY��AG6FH9��c�?Ζ��Wma���x�i��>���̤�n��#��iN7�Q��(���o��0�E_�?�WI�~r�ʟs��&2ϼRb��lv��x�i}?ī����#?���݊���b�F�p��[���w-:bg̊xÙ׾Gy����([@j���n��4�_��yx$p	Y{�nK��CA�9sj2*��k������+^���y�k-|M,�A���zq��v���ם&|���UyK4E�׶F��Y	�s�EH���7}��T?C��m�J�%��IL��x)�U�Ҷ.��x�a�w��k����,��g�[�)��iƆ�4�ֻm��������|��2)�|��(E���|J�y���<
o�R8�W���2:�u�,����e|U�F	~��ם&�9���>{�'.���I�̺L���܆��X��<��v-:475+r.�OA�9�nM'�ź�����N����T�PR��!���EN�����������m���G/����:W��{My%�|�$aʫG��Bܷ�|���Fע3�u�q�#�dSCO��bR+]p>�ӱU�d��<T�H���H�PZc�iY�J&�1\%�{���<���s-:R�>��c�K�]=�������=7�7^w���/��R�*䫔�y���٩<���zrvn;ox^�\���3 ���e��8�Y)�B�ө�����x�i��}�xc��&%F�[�R\�\0ƥ�������N��q�T���$�!��g���RX8���9V{}��:ע#y��n��r�����Y���e�":����w�+O�Ǣ#vJ�ޫ�$pL��N�O�3"Vj�s�����W=��Eg�+b������ ??�%Z���o��{>�]��>��
!�;�'O>"��&�҄����U׾�]�������#~~�	S�锴���������1�U4\�~�p��ϏEg꛾*�z�[�߄�jZA{j��z�������Ǣ3s��"����k1�R��:�|�����<��O����|�lFc�lȏj��r�*�ڷ����;},:��>�3��N�,�9�@�j��r��[߅�]��cё~��bq[LgW]d�U�t� N`��c���w�e��c�|/6i�|#K��eR�(v|f�e�ⷝ7<r��I},:3��uY�zQ���2'��g5����m����p�����8�_D�z��R�
�����2N��7<�2�����}w�۵j�b\�sg0������Wd���<�5^�Xt$A�v5N���;2�H�2c|j��z�	o��w���!**��@:��[u&W*�,'�:#���~�=�Xt���"8&[a��L^�̨���ȑɓO�����C}V)u��N�]�{�cZW��V]c�%��G��/},:S�s����S�>�4GK������<�����H��o�|�ԇM���hZZl��ι<��/�c������0��nu�I%���Tb&i�{��_�m>y�,�����e79�g'<��]G�������Z��Xt���e����L��%!�+(c)���=���>��EG����8�����6"/��E�T4m;���|�;V?Z�
���������{8��/��?�ѯ�W���K+���?��E�0�DJ%� R��wE���G/栏�P8=�J�׆��+�N�V�#Kr�w�Ʉ7~��4��"u����"�k��qQ��n��8�?�ы9�c|,id|Q� ����Ԃq5�-�e����^��SuÐm/B��ܩ�N݁��LS��e���/>�S�?
��M9�?���e^k�q�w8��G/�ݩ���m~y�Iw�C��µ#�h֒R��%��G/�vݩ�]Y��.j�hd�5����!i����n5�|��_����+/��eFc�$�^C�,�a����<z1_�N�� ���(Y��1��m0�# �mL�����u�t�z�h%v�1�{����&g�HK}������u����r	5�sqE�!�7�D���ʏ	o�ҡyX�
%B)1��_���g��[��FY����3u��L���J����w*�|�Ts���=������t���+8Iu6������|f�F$ YMG����^�E��5��fW����{i�z[�Zi�ƣ��G/�ݩy�`����2��"5Z�J39������<z1�w���xU*��D�#�Ѵ�Ef���}�:���^��룆��=
��'|��銜(iY�;��=��E��X��Y��u��u>�G&I)��v��;X��S?��G�3p1S&�*ˀ_�hB~��A7n�����s/:��%n8a�C�=�ьɜ��N����d����O�;V�^{HE �1e154�)mV�h�����7<���|,:�w�� ,��&���_��������{,:r�W�!"N��l����*@iT��X߶�G�wݖ�Eg�����b���8�M�YQe�cn�ox����cљ~��$yǍ������y_d��˲��R��ї~�EG�g�y0Nv�s|I���ב����<.���K��ǢC}k�T뵌�<��'��l��������}��c�^��`(M쯃�o���:s����}���`��;X��O��;�n��N�_K�"9��q׋��x_:֗>��QsC�i�0?Zu��%����<����Ɵz���NC��;A�*��b�������x��C�D�"���=��ȃ��X��x�̟��|�	�=��8��@�إ[P
�����^�����ݞ�AJ\�IQ�u���B��m�)x�"/�������� ^�Nh������"��ml�&���G/���)����y;��{�Ez�$�W�������u�G/�M*���Uğ����<��z�T�E8�w�$x�ş�c	-Y�4���q^�'�m�u�����<z�o�S�&Ҋ!�82Jꀷ`(��5L����"7<��G���L�E�ψ��u�=�b��.,��T���(=��=N��4K�To�Y�X���)�R�ֱd���G�MN�q"%!$�fr:r�wW:�Jvv��t�Ӧ�7}V�T�՜�܋>z�3TSE�	�]AHB��yq��Qx�N�!p�A;�O��:`T$��z�m]��G�MK8�ǂ�B��    ,���1��ⴛ�$��jAx����Qx�w�cy�(9�� ��[�MS�ºw~�l	���G�M�@8�'0�fu�G�<�#��� (�
"�:6n�y��>�p���.�g������H�%NL�E�9[.�yã���8���D�oȋg۪�Bi����X k��|��qr8'Í��O�CD��}W	�1[�" �[�Oݝ�<���S�#+����µ�S���x�����ؼ���C���S��9�ؚH����D<�qu��͹y ݝ�<��˄Su�������b���#$�(c�C����:����̜~�s����{����Z���$��?�<��M!��]BN�,���)��Y��cyD}y�Kw��fn"ӏ�6M>%�@���٨���$��57q�!�o޽�w���U�	�]`d<�=ec��s,��]�~ã���;������6z\��u֛�'n��ֶ>����7���H.βu~TO>ܣl�ʑAh/��C�<��M�j<էJ��.���i-��j���U|��|�;����7���T��vD�le�$���T6��+xx_�r��y�㛾�x�o��S7)D�`�#�F"�eI�:7�����7���L�SFV��P.�@�l�۰1��W�睇<�y�����ZC�Z���`�g�3���;F��ܸy�!���^},:ӿTWY����;2��\F��,ՑJ�����g������ʂQ"�Rg_��ڬ��-���ɛ9S95g�|�S7p�Ò�ǳ������i����H�̝ɩ����ob�@���3_��f�KTuǟwry3�#��zZ�|�zg�jH�����9l��!wry�Gr
�����֛0�G?���䡵ϲ":�y�!�7x$����#0��g���M�?S%���r�3�y��M�KNչ!u7�EdD��f ObR��yX�����<�_u�~��w�jc"<9ߡq�9SB[]$�t�ѝ�\��ʩ>@ETWR��+yW*�	6_jc�>���;?����r�o--R>n��L��fX�ese'%��e�]���?����4 a3�i�ȷƺa��|������ϐ��A�Ss��{P:�	��GJ��|�����9�;?Cz�N�'�Cr3�҆�w�ؖĦD���:����3�7�\��<�Jb��\l�����jV�O��������M<�N��Q�M˺��Ϗ0L���>[L�7#�M�gHo��t*N�4��фu��E���ԝK�����қ89�����8�y����H9Mu��������!��o�S���-5uᗔ}+#郞��r�s"���7��|�W�/��=w���5T6SK\ce�y�yã��0���c�
��I����<�V�.юm���L>U����:c2ɒ|+S�4i1��\�J+#m;ox���s�S�\!f A����W�����f�o�g�����|L�w���+�X��;�����Zۏk�ox����S�!+�� ���ȷ6 �e� �HȚe\���G�_P9��"�n�J��ْqo��=��������ľ諼�˸�ZG�$�|V���|CD��Ew?���3�}X9�;�;o��}�g#�����X�!��m��/�}X9���,�sDJr�x6�@��U�mM{����>�Ӈ�>��#a=�ct�e�V�`���b�g�7��rL����P�����3)�$Yc�}V���@�����H���RD�2���M�>@ݻ�0:n;��#y�c+�tl'!ɸ8����e�S_LX���7�����䍎�ӱ��tu�,k��p>��(t�^R����x$otl嘎������B��y1�"�ܨd��ֶ�_<�7:�rL�vf� C��}_�w��-�Ջ�"��э�A����1��m�+$���g�IUSw��;�_��3���.���<.7'�ZH�lE��G��Xa���G��:9�c+���X:�%�\yq�͕) ��d��v>�џ�9��)�H��� ��^��*��w_�}�����rLo7��nzd�j8�9�IU��d�.;��{����Mq,��	�M��sՆ�}�+��iǟ7~y�c+�tl3)iI����T1"Q�&FJ�M��7�����U�cc7[�����#,��(l^8�g�	op�лMEXԐ����v�d�m2�s�:��}£7�y��j�6�~���q�RO*��f����?����c��q�N/idP�k:2��h�J_1��w�g�7��rLx���i|_ڼp�:8��9�O�����7~y�,�t�S]�T��=��2W��n:�yI	����}���1]`Y5��������|k�5��6�R��x���Zt�*9��$��9=[�
�AL�I��Cn�l���0[���+�|kF�g��t�7~y�_,��Cĩ�q�7�e�՚�8;ݕw������u��Z�i�8��4mz'cU�׾?��w^w9��^l]V�[huF��Z�ZY���e��=��{���u�c�N�Ge�g��<�2gl�����3�^w9��F���Y�
15��ﬄX�e�����1^w�-L���Q�j�/�	�:8���
c��?���u�c��i�8�!��{2G�v���5W�F܎�n�4�;�Ssg��_�<�:M�}.S~v6`�#���ៗc��8��J�RR��!�sg�󔆫T����ៗc��e�T=�W�ER��j�+"�Bݼ��� o�������ӠЪS�k�7{1���קo��g�7��r�>Wq
���ؠ�|�0{�0�E��s�y�#���Zt$q�k[��bp��s���tm�+�?���ɗs<�A�$
Yv�-&�k�TM��M��]~��� ox��O�o�8밀s (����6�^���?���ɗc<��+��x��~[�<��8�B9D�y����A����9���,�K0yX�9h��%#ީ��"3�y܍��&���S}qƕ ��S/r b&���Q���L�qȍ�A����1>�:�H�6�L�a�eK��կ�s�o���_����5[)�ȧ�m��x�{�]E0���?Mx�G��e\��@f�B]��LAhb��9S�g��|>��w�9�;`k����T5F\&CYD�R,gQ.;��/팭6���"ov���'�l�7�������۱(�J���q�J���:g��̽�f9r%��oQ`Zd��KC��x0�G��L�4=����;ϩ}���_��<%5����3��&cE�+�8�`g}�E��ߙ;���D˾�
LN��?������hq�������>�O�ن)I{�������qx���u���G}~g� /�;�[�)١,�Y�R����
a;�?p���:U^6w�`z��◌�Ŭ�6�.Y=j��%7�> ��G��m���nXO��YAEa�u�;3��3�d�.�� �6�]�H���'��>��a���>�3ǁ��q���BT��1��JB�Hx#W=����>�3ǁ��q�隺���z���FQ�dWL��6t�g�w�8�9���%����|��Yc����e�pN�/��Y����G�S�N���c�ezR��ֲ���7/��Y�c3Z��X1U�\������r�Cԙ�]� ��hQ�|�M���\�JvEAp5ɾ�8_������u�$�^1X��,��So�Wm$ �8_����fU��2w~L}��-e��Fv��S'�.���o��O�:v��nGE}2ZL�VQ{��kS���� ��ѢzES��ϸ�E߮Dx��%?�-bv��3\� �>ZT�hc�F]�|�,�1�O{"�;���_����fU�bE�3��,M\�C�d��]�dӬ[�E�޹�[�W�+	wJ����4�3E�����m����3 �;|��0�S��&��a���y(T�4JEm�y�go��Uu��{3�KR��ކ��=�R6�i�}����������e�;��ܴ�S�a�h�W1gd��*���]��������e�;t�#��6!�hX���CKhW�	�/]� �?�����Z�.)4s��TS�j�9AJ�l����ި�[6g��lb�Q	�C���*��&Uq�)�Q7�/���    :������V�ϴA_�v#�Zӽف�-�]�����C�u�P$�����z���1�^|��S�>z��ά��#����{�Aj�i�!��]�����3 �;|����K䭕���~$����ţ��h��l�|�Go��-�/��F	�*�Y�����T��|j}듺�3�y��ά��+>k-�^�L�#��&9j�n�t�g �w�hQ}��]�|#U
tݍ���l��#Y�z��=�E���E�uT�0�A�z����X�?�o��$��/���-��K��#)q���՝�gj^%W%���V�r�g �w�h�γĘl���PO�9�)���]t��{ŋ> ��G������[Q�2��Y�S��+��
�����7��̲��Z-;��Q��:�tQ���0U��]� �>ZT_�K�[���X��|��Et*x��wË> ��G������h�V�qo�a��pP`���|�� ��Ѣ���@����tx��	���#�|�������̓�e󤆍�(Do�U"�8ĎڈuNv���S�F���*��$5�	���:�#��a=e�jڋ>�3���ͽr�Ƣ�СkE��6K����Dy煏蝺5ZU�u�=R��y_�Ҭ%9�g"�{M�>�w��hU�Zb��-G�q_g%/����S�!x*z���;s�x�1��z���%%N�8��M�%x
煏蝺5ZU��$��}�?JMcJ��*�c�̸O�>zg�/�w�b��me���i3&Ox9_B;3���E���<��[�;̶Rͳ��h6M	�UR:;��n;G>�w��hU�Z3�2\|F����޹7�u�2x��U���q�l~\h)9��\2�a��S��RZ�׸�_�蝺5ZU��)�`�{E�����Z���+�>z�nmٜ;�)B��%:v*��oS�1ǩkd���N���[��.+�:�%*x<��~�4��O�/��z�e��0�E6�xMr�Q(�j�?���=N}0{�g�w�hU�Um� �-L9s�
bc��m�E^�z�/٫>�1�c3Zr��%�hL��+�$����c5��|�F=ز���Y��D��\�b��H��ij�k�����g���h�9j6�.�qm�n���ܜ�S�k�V���^�ޙ����0&<��$��z\����Д�>5�1��U��ީ��UuV�p���h+ޏ
�a��Xzs�_�ޙ���E�צ$@��~^\;��ŝ6�,Y��w��3�;�K��~��d�A�ɑ�+uS��ԅCg��e��U�᝹��l�e�)� ���U�����j��[NO� {�g��OZ�?{u����W�G�H0�@�����Գ�W}�w�o���!�0|�8$t��W�$��5n�u��3�W}z�~�V�/ɗmEcޮF�\�ܖ��Ե���}���3�;uA��.�[�.�lx�͹B�I�Gq��������7�mhU��"NSPϹ�7JN�Uϔb��[�}�|�F����q̂�J<��DB��G�(s1�#3��U�᝹��l��rv�xM��wE�D�+#AS�.s=������ݒ��H��
m�xL��w���$LĎ���6W}�w�������J������|�;J@�����ި��U�6��5A�3��&�7q��s��$=�1{�gxg�-/�c��3����#���W[^,�I� i���_��u,���ER�N�q+�� ]� ��Nc�ݰ��|�F��cɍL��&�A�Q)��(n#N�/��:�es��'? &��$����9״���>z�>�VՇ�RL�ըA�%.�����JdJ�{���|�Goԇ,�_\S��T�z�}�Ȓwݘ:bb<!��y�g�w�ChU}�7�''�����s�q��sx�oq�/٫>�SB��C�|�2�71zV�w�9ϡ��k���3�3��̓6c�85R���blB���/����W}z��V�]X�-x�����~$~�T���ܺ-�m���QwA��.�@���*Ӏ�Ӕ�QT�]#��gj������e�}�P�u���.����Y\�Mo���Qϰl��$�ܩU! +񧆢Y�Y��,^_��^��zZU�P$���j���wH3Dy�4|s�ѬS�W}z�N�V�	���(B@��C��SѾ�J�}{���3�wtx�*�`tJ�`�x�#9�e4m�@(���]��;uvU�@�^�g���f5ttk5��^m�`j���;s�y�\�����C4��Q� 9�6����]��`�y����{j(P#�:��**�io�Z��ة�j�����e�ߓx�^p�m���y(M�؉u1aˏv�D��������hM���c{R��_��^l:�u�s�w3q��]���h�z6jƐ|hH�:H��f�B�T<ɒn�K;}�� ����њ�r-��MI2�>����r�ɦ�b������n���h��{nB�x�Cq��G��0Tq�{q�U�y���g��pw��7Z�ӥ������G��p�\km|4㐝>�on��ђ��%�pN��{�$�R�=d�[�4"O~�� ����h�z
S�Ni���+]`S.������~�p�G{�5���
h^_s�*��%]J��c��h�����8yo��>YG	@����~T��D2�ZMԶ94�N�����-�?]NAG�L�.���8M��`��GDS���ࣻ�Ƚђ���Z,�7���[�*S|0�#��~ɿࣻ{ڽњ�.$Ʌ
��sRᣑm��BͶ?_���=��hI�
i�qD��É2��%z#�j��������"�FK�Oʁ���bʄ����(R"�]�z��/���>yo��/�����zA��w��FiTd	C|������'���q������Ltx���Y�y����x>�����_�)�n��6Ü�����5������?�������Fk��JDԻr�e�E�ǪZ�Y��:��������"�Fk�.X26Y@!����$��S��Q/������ђ��8�7�+]G_CeC$V-���G�ʶ?/|t?�ro���N���-��V<i���ZB�m}����G���ί���(�ȷU^�G���|�ƪ�Qĵ�3N�>���u~U\W��	%,=����DE��j�:�VO.|�߉����\�%O30�0���2u6���a�r����/|�߉����.��g)���M�1g�ťt��lÅ��;q�_�Y�#W�[�ޚF]%[e�c�:�㌓�+���_W'�3��!� /w���D�����l�~)^�ȿ��Uq��=
��l�� ��:j��j6��^㌗⅏�;q�_6�ʇ�$��ӡ_'�g�6
y������.��7�es�K��j<�9G}o[Y�G��J��Q|�Go�u~U\7|,�`�����IRb���D�b�!��7�:�*��}`��zG?��r�E�!1s�Q��f�>z#���:�+�p#)ȧb���]2���b*���9#6�ࣻ:��ђ�� [~o���#m�oB�$�b�e�����	썖ğ�;�.H�c�q�JU<�uw�'�|tW'�7Zr�S���J�$Y� �����/N�l����;}����Bo]�ٻ΂'��jH��5�y��>���-����7� >�7�S)k��T[C2�����	썖�^u��	��K��w-��E�{�����	썖|w�����w@?���ڈ��*��|�Gwu{�%��\�������#��+ױfx٤���>��g����J�'/	��K�\`ߴ�}f�n�vo�^��]���h		�
��m꽫��f��5~����t�FK�{��W'~�y�#��=GI?���$h�}:�����FKλeg�14�q��Y����k��n����G�V�`o��obX��P(��$ԩJ��e�JJ��8�_@x�}3�z�L���z�[G���Lx/6�C�kO煏�;~>���H��VU��}�/U𦍹��4�:}�#�>�m���h�w�b]D�f̓
���Ak�@!��}���-�g����}�]��2�Ħc����g���!x��ُ�{�ҍ�O����ũӈCW��t�7��    $5*ʲ$��(�N����V'o���S��	���u�	��erھ{x��mFk�8Tf�*!���N+���9\�8���̉{��)Z��PxsPU��(���L��{q2y�֢o��y|��[�'j����e�3��so�f2U_�
s[:5���Wc�ώ"m�ݘ���O�E��h�j����'�:�k�jk�����G?'%�J�Ca\�9OI��GI4ʵ����>ٙ3�d���lz17ō
$�p�DZ��k癏8��썖�Ӷ�G��(X�w��U���_r��új�Ĺ�#��N����q{�5��[x#��wq��o�hs��˪N=U��g��p�o�OMc@:�K>}o�\^�d�ѰiΏs;}�����Fk��L���h%��Ypƞ��d��Џ8y�ϰAp���cg�$�5k٠J�ï"�<�mM6E�3ض��t�p�/�7Z��V<�E���1z�e��e	���Wtt�`o�m�Fk�X�w$9��'-q>r��)��~���3�����}g�$��c�]��u�]�\�L��<$��8���>dg��/�fc
�|���x���x)����*����g� ���G�-ɋ-��T��?O!�j^�%ٝ��8N�5��g��~���h���f�2�"��5'�)�a�$t���^f}��3=�f�u�Q,���y����aM��ƒ��y����G�n���FK��M�VI�:{/�GH)A�7�޼iZж?|d0��g��}���*�Ie�Y%��R4^oz,��B|ڟ�Fk���Cw5<޵�t�U	�cA�i�4�JW���h���!67���)I^��W��iJ��-N�/ �ރ��������3ɋkT��֔��Hg�	����ϝњ�(�����?��P�I�=���ޚ���=�-ɋC����:��̾��S�Sb!�ڷ�n_@��??����y١٢���	R�Ʃ�F#k%؟�[κ��f�$��V�"tG�����A��+��.���,� ���znF-����������)�9|�٩%(��aM���묿�8G�Q�W`��?��������:����[�[���� �������~��3�%����?��׿�m�o����o�6�?���o���������?�������/0�_����;({�?�O2����n������_��a�/�����%����74�_����?ޙ� ��-�;$&_o�\�r Q�fƮ:l1i|H\]�͌Ξ� ��!�K��G�R�5�?�Or����-��,
؏Q�f�fKu���f%�û,2��c�r �S�|�t�̣ .½�P[�̴���vK��[�LЀ}�п3Z��R��b�ZMWY��b��1I+L�)�{A�gIT��l�Cm�W��I~����zz�s�4�k��������Nϲ�'�AJ?�i�fr=�1�E��Pt�t�ɇ�/���8���[�B�ܟd����^�_�~cK��^���B��˫�13�$1��to�3��_(:]
��C��`_����R|��?�Or��^{)��z��\���R��dt�5���WZ*���(�F;��B��һ "�k�P[�B�ܟ��x����捝њ-U
I����$���	���ů��ζպy�}nߐ�^�}�z�zA�ԟ��x�#��F���ܗ�n}��5�Qz����Z��l�L}�/̭n��hM��u��D1��KJ=&��dx���?uG�?�cu�Fo�h�����R^^���)�)*�
�(��1R�Pʱn>A|J�|����<-��tj�1�5V%�4�b�������S}���n���"�����b@7ap����Q��ud_|���}
��P|]0~4ZU���Qת3j�u�U-���f���Ұ۪�E���?-�J�q�,1ھ]FY�hJkm�P�Vn�)C��p�a_�u�A�BV��	�EǀW1�q˩�`f�֧�'�tӡ~4Z�Y;	�,F_�i��ȲuuT�Β]l �P�p��4Z�ZUV7P�Nc@��+㉫�R��f�z$�(������"�r�[0ͨVX�ZM��p:��S���V6�(��X��h��=+�&�)&��IV��ب�Ja�`�(�~�>-��;��bPS0N\�!ipJZ|���m,r��(�n<-��[��;DyQP�B�ZRކds��6�������V���g/r�#z�]D��� E��]u� �]Q|��V�U�/5���0�BQء�����|Fq� q4Z�0Nǳ�S���,	u��Z�n�zf+����:���d�n^e�ପ����c��?������9-���>ý�<���BQ�A��J<4�6[��nG��VA!Xp�fNqP��Y5]]7&��t��V(�zW6�UǊbr�r�P�P@�кJh]�.�R�W�I�D7�G�EPA��Π�^�P�U]G#��{�h�(��%��h���V%ӷ���Ĺ�ژ���2Z.�	��K{4Zu�a�vIbNث��EIL-9l+���V�^Q|=a�h�jDW,8���-k=<�ړq�9\ݠ�3�;���*��z�D��驣ֺ�T�����w��(�M���h�^�c[�2\ůV+� Br8�I����,M��"s/�w4Z��
�I���P��Z���^��P���q1�Q�u��Ѫx����8R���h���+�n͏-���a���"�N۬���th�����}	���Hg��U݌V9�hk˨�e���Y�,�7�)�l ]P��1�G�U��0h!M�G��H�M0;Z#LQwy�U2W�էѪ�5����w�c�x5����U2�XCp���N(��i�9�� ����U3ʏ�=�d�OӜ_�=��7�@G�U�tҩh�Z���R�jAbnɭ���;�O���Ѫ4�ySX%�R�J�#}�h=�3^M|B�wjG�U�ٞ% TT ̀.�3���5d��O�g��x�0q4Z��f��>师�JB^�x���m��EP:��w�{��h�H\�)*�!�c�Æ��is��K񌂟.�?�Ve�ª��S��� +@���H�cd����tB� �!^�0Zu���Y���IVu�f��\�,���l���"�*�V��&��*L]j]�Y�d�f�>B�s��ޱU�Eܝ��w4Z�\��DM���+�f4+Ak1%�hL�)iƚ(�����XwF��j�p�����ں�A2k�L3�fm�(�(�F��U�u5��3V�
5���>�`�N(�C��3Z��fS��Z��*��$^mI[I��8�1��	�dN����h�_��p�6x�K���@��ئ�!kF�nd�F��&JPZ*.���Q**��$�i�x� �Br���,�F��UE�n+����A���I�'y��+�A�'N���V����j��k�'��N���=���( ]Q<��hU��
g-��G��ʡH+�:$�̀X�\PܵJ�V��Uwc�#c��?���)K��h�8M�愂�����h�_����y?�:0k,��<��6��P�l%�����G�U�*��t�x��U/*�,x��Flpc�(`sd��+��ñ�0ZE��d�E�.�*{�EM!V֔s`��(�wF���� 1�j"b �*7<�C�8F�%O`���a�P7�e�����h�L�
�p%v2J��P51Nb5��"�?��Vݯ�^LŴxKx��*��U5%�$���:���y'�u3Z�P�)�q ���ZW�d�ՒP����v4ZYAf�	6�&X	��T z�e��u�;�tF�,vF����qvP���� �+�.כ!�y
�0�Q@��!�0Z����,��ܫ��hy�ŭ�<g_3�+�gg����a��N+����KT����s�#�Q܍=-�X�H����$�f�A��Q:�9Y���V�n��hU��\,���YK��5�6�7�H'[љ�~>T	I�����3cE8��V�}�ضU=��χZL�B�A#�
���@n�a:��7���F�ޭ������ ��*	�G��!�df�ә�~>T�c��+jv2�Es��Y΅j�V��V߱����߻E�I����ͷd~x�3[�    t��t4Z��]��y�勲�I��YB�@��Z�W(���U������Q:�Ui��� 	��=�^��C��wk��I���JR@�������^�*݈����[	���z��Ki���K$al5»az {a���s�]<���
<�g���S����	Řy�j/l�ӡf
EK�"����^%w�<�0����$;���
��j3Z���,��������$,�9'mCۥ�=����-
���W�Į�P(RP5s#��Co1M
�g���P��F5R��ye��@��f$���񼳲g��w��tV�� *�I$�Z�h¢��}⹈[�
�l�l���f�*�BS�?eD���ѳ2�⢸\7���(~&��!�!;4:�����1�l���R'�[���۲��*g%ъCT]�1�K,�0e���Z�U�(�C�O�UA���5�;���ō���Lo�ܤ g����T\Z��ALȫ�/��ϐ��T��pgw�/�F���6ldsJ����G�=q鎎X���;TqV�y+8V"`cY�=�)W��?�<Ȧ��%o� KOU�2r�M���؅+��G��Ѫ��g�ilT�>����*W�����C��7uK�����J1�M�.�Y����M��2����I����Ԃ*fdP����-0��Q��^݌V�+�e��eU{\Z�d�V��jm�^�3[���O�U�UlPw�(�0��"#�r��v
Q3�������x�_Bo8�j2�(��K��̭��VhP{� �Ѳ���\�,@w�0����+�1��%�����g��;��*b-REAK�+N6@M�fW|�Zuَՙ��>��|�JXL�1]�'T�x �TTf#.��"	քzf+�O/ןF��j��o���ƣ,\� <0�ȥ7����g���Puk�h,�&Y@N��z�T�aM��^=��χ��Ƙ%c5�
^	�e�)S��E��jƫ|f+
��!;�U�*�Zt� 0�zM7�h�A��F�5����gB�\���T�S _�Y��J(S��ں��l��z� �A ��R��E[����ގ�?���) .L�������ǳE�\�jU��I��v�1�_��C��	����p�+�*��*e�%�Sʀ���~:�`l��
1�0sY�+k����Q���V6>�~-{p$	�S��%a�$���d4�f+Aq[k�3Z����(�V�;LgM���INU�aXr�	��V6>�Y}�� 6��8(��&��d{E�-�L:��9�3[9�ƕ�f���*9V�WqG�IN��F����z�f+�O5��F����K"�F�x��%c�H�:#qL�י��
'��#�i�l�&[���k��%f馲�+��*3̈́%��
(Õ�hX	��&�&l�e+��?�ro�"�6�U8��G��g=C�0Z�\kY�+��HP���%w�܌w�dL����;xg��=\6 �s$f� F3j��Q�6�;���@��
5Y�03��,敌��U������U	�-�2�����v������Ն6���(����h�$��Xj���0#U��cRw7�����?&�Fk�R#�E�e�!��Ď��Fr�@���C<�OE6�F���x��x��bV��v��ҵDU��*��o|��hRg5���o�C1����y}�ɕagX/ �!�!M�ЩI1C��(Ԃ#�&=��L?�D�;��P��h�$��S�#$wd$-�k�Z��X��G��x��0Z��Si�e�B��5�a��������V^�ߌC>�AjF�;i5�v�+�_�̣�Pu�m<�YJ���#�0Zt������S�QE(�Nr��|{�X|����Z�3��^����Z�2���5��&&畯�,����?��O��F�ξ�1�IZE ��>�4!m�0���!�����x[[�7Z�Ԓ뽡��7w��fW@D�u�>E!x�_�D�m]��AZ�ĨFR隻�}�����w��y�'*�@нz��h�?����h �� )Rgn��>���t�ok��F�b)��,^�$�tֲ�*�X�%�V�x:މW� �n[��Fk�zaS�f{5�v*�Pa��@��K,=9j�]���L��}�-:�.y4���P��(�H�r��Yo��;� �f���h�?-J��H�$��#壦ک��fԷS�����H���Ub��[ݩH,��njV���*�X��'\��p��{�E�o쐜��5�U����$�/�{gQ�N�����y~ۈ�JrJ�6_��P���9��gv����)��h�������=6��K`�{��ۚ�9��dI�H�ѢX*b���yݠ��I��kK�g��K��3;IG�JS:��ѢH���f�$h[JS[���P�8Ɖ��b
h=!݌� MS�N����W	�?���.~l�^�3�ȦFk�J�/q�h�L�����cd��	V۠�T���� ��5�F���� �S�vt��9��CJ;_Cc"=p4)Ó��4�k���������v�Z��I7UQ����@ǂ��l�Iuۨ�"�V)�A%�P�	J����Q�b%�0Ȋ�Mc۩��PCJ6��EK�m
w'5ZYlY�9��kEqw�7ZÝ;�f�:-�6A	�y�� 'n۫�"���{�EPK��­��Qܿ���3�DcT{��n�o^��M%�rM�@L)/��X_&�tEq'��7Z�"H��9F����a2@!q�]N�����Q����jo�
�l���ZbH,Bo��i�VR��c۠�o���r����Yo$MiT	�v�(Q�~����ŧѪc%y�gꪗ$P=A��%�bI���٘	՞Q��^Ž�*���sE�*��������6]K0Y�bO��"�
�VA%���$y*�
 5.�ciB��*�P`d�ͽ��hTT�T�У��d�*!p�	)թ���{��-�*�n��٣�z��"�,���T�	5|;T'���S�j�6���,��ӌhЄ�(����h�֚�wɥQ .�*�8���i*�n}
ޤ+�;q��Ѫ �H�,)���� �TJ�U߲���~�^�����-#�Z1 D�SZA�5"ђ��'*(��P�le�;�/� U-�H�(��(N�Y����Ep�cEg���o@���W�u�&4�0tG� ���"^�+�@g�w*{�eleM�#��Ѣ�W�DV��ъD0�x��ꙭH?��F���H�	Q�0�$l�Î�;u[uwy�Yљ�����W7�U�U��J"�J�5@G)�NPpM���L��V���7��,��"D
	hh׹��%W��!1ɬ|�P�l����j3ZU��PiJg��:�Yٚ?�m9���
��ϫ�jh�IͪCW��
(5I
|2ŉ��qJ+x:�A���4ZU�KX�lBcY�
��|IAs�:�˽=���ʥ{���vA�/�*��{���N��-4WI��L�g���g���f���hT�B���j *	W����u��`��e��3[	�g��-��	��|i9V�Ud�T�Mq�X�pf+o���F��J�ߛ3Yi�����O@��Z�)�yd�l%(�d��F���\}�"����Fpq$�j��v�+{f�痵O�EP�P���#�j��ئ0!ۨӯ�3[9��OP7�U{U�P2��FƬ��S��
]�	��Vl�� ��"��\Y�ꥢ�C�i)	��5Jp����왭���[mF��jK����4�֎6VU��T�L��ʞي�I�������F���%H(�Q@�$n ����j{�p��e{�EP�x��bV#�d!\tg.����;����z,��h�z(������Q�����h�y�]�3[�;i ��4�gE����MC�qiI�*��M��7�Y�#[�_�x�{�F�b �}!\ᱢ�@��Ԧ4�����~���h�R�����c�0&שcIU|U6S��;>����h���S��H��B�%LA�(SK��ԍX�?��0��=���"�)JtRQ���T���h+��ۛ�҈3tጂ���hժ�f%�b�=��
t�1�0G��}qzXx�(�
+�F�V    5_y�������U�_����2�>�Y{��(ܭ|��h��cv�Mܯ:�ʖP�U�a%X�S���+��w�Z�ʯ��$����V*��]�n���:��*���G�-��tx 3p�օ��<��!Va�1)��"��6�UY��$Y�2�*Z� �AyH�Vچ�A=��P���U���A�Q��*1 ��ѕ"��m�3[�;��;t`�L�m��a+��f�X]�6���Z�,]�3[A��!c�0Z��!�
i����,����Py^���óŇѲܪ
������R�J��%H���W��V��z��h[Q� M���PN��D*U�e�v�he�g�Bw�C��a��/�ڽ�ʥ�*�X5Wt�����~>T$��T��pX=�6R⦩K:���G�ڌA� P��+�v�+�_�P�2�y�M���������A59��}?P,l$��0s���u�g���l��m��h��`�B��Є��.��eO�o�zf+�x� �Ѫ�7�E�� P�@Uz�R���R�3��g�OuVF��BH/cT5�Fn �] �H"�I��V�ߎZ��Jsǅ�d�p��(�'ce�n�ޟ��=?\~�b+ם8~(A�V�`�����>��L���l��jm�YKƊ7֩��
���T�������Fˮ�8q�LH�0�85�H��1=n���V?�K�S� b�z�f�8��+��^�x� ����~��I�V�Qj��W7�.�AIZg7�g�b���i�*��E")�+���h 1�8k��O
g���P{��CT�aHhmd}��Tsε��J8��χ��O�[F ���11�:�⊥>����>50|-W�qF���$���S^��X�=����x�k����	�
��Ny��R�b��˝���pf+�oDV��*���mT���Ae#�jT�V�j#[�mP�l�И���F�:W#�-�˧�>w#�k�j˭ԾՃ�x�|e�a��s5�@FhJ�(|~�In���>'��� �SOاѢ�/�~�jU/��CuV��8�ˡy�(�=rՇ�*�����0�$�d�XU��Hu-,;�nP\E�-�����hա�òZ)��:�K�����g�z-"�Q<�X}����{�QuD�N|>
W���s���[`�g�����hU��ѝ�2Ѫgܬ��zI˿����*�
k���O�UPc���7ė��fiMP.�}� |B��S����_5�1��`��UeX�VZѬs�`k&VџA���O�E^O�����
jI"�k"Kʚg�rԭ A���O�E��s�@T5��pi�ʶT5��UB��ypԭ �T�i�i�f/Y
GT8�u���ԮI�k=�ӟ� ����hQ��� �ծ,T�F�%]�1YO=K$0+A�7�F�z�S>��g5�TY��T��S������[��j{�E�T�� 맘��Q��%���ﯷ�n@ܫ��y��$RIC�dM#z�J���a��x>�Vl .�>��� �!�|~�q��1e���]KX�~{�:
W �cЧѪ��6��Vr~�;�l�!K�j��V�G�
��O֟F��J<|�I���_#�TLU�V���o��O(\|��4Z��f}�\
��BQ�Y����s��x�&m�z�)��nU?�����ZYVU�*Ƭa X
^U�0�t]fJ}� �n�C!اѲ�j��JDW�ƈ���ep�c��p��錂�R�O�e���B)%JA%Q�+�T*�a�}Aq��7Z�W��KS�8J��z�ʢI�(Ciׅ����@����?�e�ڗ�0[�+Z,4��\R!�V�@tq7�xo�H�	J��	�ܶ+59K�
	�0G-��~��^��h����������)Z��:-wb�9YY�-�{�⁫>�A������=�Ȫ���K�z����'T�v�����J�=�������bb�uB�'�#���0Zպ�6%
�i4/�Җ���Zz�]B.��jx��!�0Zճ���JRU��*-Vˑ�E0���US����Bc`c��d V� �!q ��г�)O�;��?���z���j������/���ȿ����7����/��o�_��o�������>���:�����K�����Alg�}���|os���7�>�t�s{�3Z�ʜ��Ղu-͝��K��I��0Ur�8��3
��vF߷����u�ֻ�e�p4�>�|�s[�s4�>���/��h�h'�l�c��`4���9_�ZX�ȩ�>�/v(�voG�EPIK�h�P�-P�Љ�L��g�.SP"|j_�Q|���Am>��tVݠ�]�P�JJ%D��g����"�b�a�� ;�o۵t���~����/ȏ�QbP$ș3�$���#�0ʌ$>U0>Q؛��h�j+�¦�(��$�J�.҈Q��L����S�ŝ���h��Sw"X���X�F1*���%�:}��
�
6�#����ٵ��~�vg<w��F������|R�M�Q�⡲e�Z��L�P���iL�����+t�k[;Z4�1��}��� Lo��,��(nc��ѲR2��;zYU�\�Tg7�JֵM�����bG������+��"�`�����R)(�ůt&��a<�1��+�����F��c����e B�S@K�����7�z�Z�
�;��nz���V�Gx	︸ט�g����3B��1�_0��~u7����v��+��g��VEM7٥Q��1u�s�gBJ��l��� X����A���f�R�'p/����5�b�ս@q���F�n1��Sm��3�օ�8J���a�2}��3�;�����Z��7r)G�U�#���(	���eö��:�.�9�yGn���+��W��l��Z"�mg���B½�t�����`����/����F�f[?��JD����Ơg[��"�(���m׺�x�7���h�F���T�o�*�I���a\A�3Bpg.s��������e��.���T�TN4'@c��j^��j�9?5�3��}X�7���=�ӍJ��h�X�(�v	1��U��t�c�YR_�(����Y�C�^w3Z����((}�kZ�2CU��a?u_�;s�m��h�u]�I(�:�Z-aMɒQ�4��ayjw�85(h����vm|����ԣѪ��\�ɩb�	�(NM��Vcu���h&�tFq7c�h�m��/��%�{�U^���3L.��x�QKU��9�h���esFq��y4����+���ѽѢ��=u��՝����sl��2�$p���x
 ?����a�F��mHH�٪���fq��;�H7B�G�EP��J�eUѸ1o��!�,mr�	�M�����v��ҜS�p�>��t8㡛���Ѫ\�I�&ၪ����<kE���������>�bF�b�,�cnY�b2:D0/����rdq�m�x��Ń�0Z�8H:^0ź�9j�{�D�얬�3
���؇ѷ�Zo�x�м,���.E�ꚂZ8Ҟ�t���6�L1��������������� �b#l�·�Qm����}��!�0Z���5�F�kH�Je	��ڰa
�N($�z� ����Z>�7��G�E�+��.\�j�\9h��>>�K�J���������ULG�U���q\Um��A�T�����[r�RW��(w�f�
�d��QTa��;r��!�
�Ŝ�Л/�1X��w�M�����vm�⹽���Z�(��Џ�d2:T<S�dG�:�������?`;�U����4�!���ǥ+��&3Z�BB!�(�W�-��pv��|4Th2�S�y3�[�8}m�3��F��ѷ��`�x�*��F��@j�I�C>��E�kA-�ף�lv[�ZpW_��V���މ�D��mw�&�%*P��\�}�@��(�V�;�
���ܽ�!xDKA��ZAH;���R�g�>��}߮/�<o��{f�~�k[���R�u�
�˸e�������p�t3h�h�꺹��0�a?H\+PIXk�W�ӳ�2\,����V�%�l�*Ѭ�Æ��I��+q8    �h 5Qt��\p4��]�<a͇Ѫ���ŋ�j�x ނ��y*��ZiF`��(��u��h��1$�����T	k��j�.�g���.�(h��hժ��]��Gܕ�8�aNyHXP��m׺3
��`F߷k�����vg�*1�q�(9�/nw�@d�-���G�z�!�(؇Ѫļ��d`�Ŝ�RkA�܌�܌��5�1|;�c�f�������jU����OZ����7v�f�}�6]�<��f�j}��4�$�X������򖇦�ӗ^���PNЦώQ�v.L�+#�"wW�Ĺҙ����cg��i$118e,d�|:	�Yהu�����z�����dcG�o۵�
�x�Mb~4�>���M�/�����@��עG�UD��G	p�3�D	*��T��d�%ə�5ç��ŗa��hU�N��nϡ������$��;��+/P|��s4Z� ]�Ka�4����=t�)��c��}�~|���ꇣ�a�}�6]�|=��h�*�$�������"�h�*�nfX�� ����{J�F���aR������9�U��j�>'���j^�x޵qa+���0Va�J�Q� ��:�:�.��:Q�	��^~4��]�=�7�G�U�͘]�3�� �ɫ"��d�A��̌�>s��p�l3Zฒ��({R�#&5�2G6�9jS	0�3����h���A��q}��>�Z*e.*w��KeV�D}f0�ᲣѪ�������%�ťm hç�{����zf0�7Z G�U��C���"8p]C�{��$���P����i�h���)�7�I�e�c�Fs��$���ꑷPts�t4Z�[cR���ݢ76c,x�/�/}q)ƹW��G�S4�a��jyt�������btID;���f�=�	՜Q����h�z�'v���" de��9߹oP�"�W�V�U2)�aUO�q�P�*C��^��� ƞP@s�a�~��9`�ٯ�;YK�mo�W����Rm>lP�E���<���OC?d��MH�*I�e1Y��cَ�P�}���U{5��F�v���sQ��U�w��{�����V&�bhv\}y�q4��˄3�x�a�F�:�l�7����$�Ig<�6��-j�w�eR%�Mx�u54	f�I�#�Ss� *�@qw��7Z%m*�A/z�]e���'��ݖ1��(n���hժ�Zb/�y9MfP�a��$�n�F����N(��3����v-�3󫾹���R�Ѕ��۩���w�k���Mi�Ί�H���������/_��ec{�E��	�~�+�ֵ+M/����%��hT&TFA7G��[�p�s?�����]%xT<�p�g��׭㹺���zf5L�y޿���ѼZ�3�!�z^��{���+��t?�,�*�3$`�$>b����57��G�o[_{�7�y$��h��Fݢ��)���ZCE��R�Bɣ�-Y�g~ä����}�����)�Nm3Z���e�w��`�g��Uh#����97�3�Iꠟ�w}����M�<�g�Ѫ�L�ވ�˱7�����}B��,7��mN?{�>��-�ጇo_v�F�Ze����鰡?2%�J�QیӒ#�1���+��������7����?�V�o�9Gʄ�1�s�2A�{�܆ws It��)�h�m���ϓ�0Zuo�����ggQG�����i����o��3�xS�r4����g<���h��{����~�2�߂q��\�nf�~tG~�r�*o�F߷�|�c��Ѣ�-���1�Hc�z'��zV����Ù��9F񜿅����Z�p��um��h�{���XU�5+7J�������[�`琍���݈ͣ���o��y��0Z���L4�Q�uI�3�te��ג��R�[I����W{�o[_6/�<�F�^�}r�$���$�31���(R����������9�h�}�k�x�n�>-����chZ�P[-A<7w���ݝ��F|�_q4���=���b��Ѫ�A'�U��i���qE2:e���� n����o�n��F߷�g~���~��hU~a��͢�b��E�A1*
�d��������f�Gm3���=��<���hUAb[,���@wuw*��7M�z�z�O�
w[��7����g~���y4Z&���[֘��!X��X���u��-�93�3��j�y�����]�3���Z��Ѳ���'	���u�j����0�B���7�7n�M�F߷�g~�g���0�Df�����#�[j�g�b�U;��o����������o��7�U�E��5I(��(��R����$_�~ǟ���&�������o�󼾼�@���Y�0����S���J��9.;���X��a�m�Τ����}�3)c�A��Z�4��>gE	A��]%W�2��c(�fQL8���1�܌�uak���5��AP������C����8>�_|�������	��o|7��h�W����h�,����U�Z/���NP�m*}�ˋ��o���z�����7���?���u�j��!�/d�#Ơ�K��Ї�����s)ׇ���oz���~��h��6�J"	�mh���r��u�^�a�_��X��a�m��Ѽ��@F���%#�x(��RֲZ��U'����-��G�R_��)52�5Ƞ�
�m������A�Ø����S���"�4B����Iv�KV���Y�`m�gmtWO��F߷k��wv��p�*Pn���z�"�����Q�KI.r�ۮ���}���0������}gS���w�/O$�X�c�]����p�Y��v�.����DV{��V�6t4Z��%6��f`TEy�R��GvTɒ�d�tA�of�~���ÿ��ͭ�7]H��������=�韻��$��;0":+�ϐ�8��-��Ƭ�IN�X{�5H݀���=$t����}x��7����Bi��u���������c���њ�md���#˘�����$���&��hLB��s�}��^�-�6<�֬���m�JMB����*�`zN�mMS?-�3�av�#GlF߶�g^3w�[�F�|�u�4��l�W�F�*X�����Kg2�⎏H���%_V7�p��f?�֬��>6��5�p/�d��r6��ͪ��\f��>��muϬ�"���6�y]��9�dkN;�'��v�i��L;���n�Ý��hUy��a$�UG��!y��M�@u�U����_P�n+�F�w#�mk�ǟ��g������_޻���&l>#���*{���ψ�m����;a����v��7�N�����{o���c>k~4;�ŗ{�U��J��%��Q����U1����SY<�3
LK��{�U�ܜ���c��|n�m�)�Ԫ�����v�$?PH@~s��7Z�$\�u`�&E�J��2�-��Ww.���D�O�/_c� ƈ�\�HG��À�Ǖ��]�ؖvDmϗzJ��*ǮU{���ɞ�Q�r��ʭSrYL����s�ī�>~3�2/���T��p��p�bQT��t1W)qbLd���Xĉm"X_��=c�[��p���`�m	��.�)5����In�Oo��x��8���D�x��8�="� �B9��eF�-����I
�_����=�ϛ���]���B��x�T�V��[@ʙ]=��Cq,v8v��1�s̼���4�*�u�v��a�A�]�P��f�b+� �t�3/�p�I���P�]�V����s0h3���Y�\�Sk��7/5��&�J-q�8b� ���.�[��E�J��:?T��h3�c�+;��{��M��'�^��BU����[��S-����Il�n��j�%v7H�?U���%w�Be���w����;ϻvaw�w�[$NT�hJb�[k좧U�iP�O�l~��)����՞7���.VIh�Eo���ч���pl��j��.8�	h��aJa
(i;�Xĸ(�b��-�sǢ�v��VI0���5�ev'��c��x�b3�x�8�0v�@T�ǎE�}�����`V(i,D��f�����5��)�h��D7Y��Tq��&`H���G��/�a���1).b
��1�6�X�V�u  
  L�qn:�S=�aq��r�&'��&�v1S>2�E��-v�@T���^ҐV@#���}X?,j]��\(19/�T'��hv�w1���m"q>a��|!�,��ywb���
~d�۰l�6Lۺ��?�s~�טB�B+K*b|�a%�sC*z�ݼ�v���Up� ��f��#��z:ȏ����X�T�V�ʲ*�=�s6��~2�ĺ��e�^�(�Th�HEo���r�������P/̫��i�?"J.
����b����:�cvG`�`����4��5aoq�c����|�|P����T�Zp��$Q/V�u��F~�My����|�ZDaJq���s5�r��o��-Gs�i=Bkx�&�`E���A���SG�����p�8��ω�g����N���27�_j~i~����:jk���* MJq'�����	��`Y�,h��;u�3��9K;qb+Ld
a0��[c��0�(qb�8�����'qb[D$J��R'���T�x*��v9���r*���9Q�ݾD�ؖ"jyIx@+r�Z-}�8�%&҅/���[D��E��:'z����8��K�(ۖ�D�$�K�jMr�8�3�ԅK���;sI]o��8�3�4��TĈ=a"i
�&����,u��"Nl�pe���qbc�D�C�[ĉ�]R���R'6v�N��KQuws�8��Kv��]����L����%��ZJ]"FlG}y��%]!�$qbg.�v撮���8�	���p��6�qb.�6��o��Syto`.�6����R#����<6ᒵ��[ĉM�dؔK��n4���S.�6�-��Ỏy�r��)�lٔ}bV�ؔKv�M�d˦L�m��8��i��_�؄K��M���e�TĉM�d؄K6|(f��؄K�������M�d؄K�������M�d؄K����n��[�D_�rɖ��	�o`S.�6�-��'�|��M�dؔK��ۆ���Kv�M�d�!��\��\���%}!�11bK���cg.�.�^"N��%���\�f�"N��%}!�1qbg.��ۄSĉ����v��"N��%���\����8�)�����.`+���cS.Y/\=go`S.�6����&Y�l�%;�&\R����pU�K>���"Nl�%{�&\���r�8�	�� [SD-.��	؄K>�ܦ"Nl�%X<g`.YKɸE�؄K�/'6�=`.Y˃�E�؄K��M��sHc*��&\�� w��M��	�|�Ւ�8�	��e��"Nl�%;��\����`���	6�-�+c� `S.�6�-�6cd`.��0�9�v���	6�ϳ|S'6�=`.�<�#qb.�����8�	���p�z��%��&\�!��sf8 6�=`S.�Ro3f8�<{Ƿd8x���\�l�%[
W���\�l�%[�m��&\�!�s�! 6�=`.���9� �p��	�lC�a;���-��3U �	���pɆTϙ* ؄K6��{��|�&\�l�%[�m��|��\��pe�sl�%;��\��p�m�ϳw��γw|C��%�Ħ\�l�%�<sB���[��=s{~���[��=s�{���[�=s�x���6�㞹a<����pɆ�q��0.����y�y;�E���6�-�k�ȳw���\���b��Y��Z�/'6vI �~�D���%;��.	D���qbc��j�z��M�山KQ�p�D���%��Z^"Nl�@T� /'6v�N�)��V����r�j)u�8�)���R���r��	�-�`� �� j)�X�jE���	6����KĉM�dm��-��&\�>_�qbg.�Z*@�\f�;jj8M�D���%�h0�Kĉ�]R��h�Kĉ���i�'y��UF4U[�o'��D��i��[""a���o'�BD�V�jo'��DS���qbD�\�޾E���o'���t��*n'��D�a%�D���%���y�"Fl��j�-���.	UR��V̧�����V�[ĉ�]R��u�qbG.i�Q�.�8�&�\͍D���׶XJE"N�	��|�+qb;L$�`$���	���VqݎD��&#�E�D�����	�8�%&���Hĉ��T�z;qbkL���#'�ADj,g8D"Nl��*ۄHĉ�����������a��ܞ�8�=&��F"Fl����ԟ�%���HW�	��[b"[>s�D��
MU��E��U�j#'�ADҖ�%#'��DS�.qbc���(�D���%�T�U�D���%�+��D��SFT�q�D�ؑK�����.w^G"Nl���rK$��V�����8�uB$~+3"'��D�l�b����Hĉ=!"U�r�D���A"'�GDa�(~��D��.%��"Qy�o'��D��t�8�%&2�R*qb+LT�	�8�5"���Hĉ�?�
ʍ`����Xc����ǯ��?������o�/@����Ǽ��������ǿ���������Y̺j>�A���l�޹ݻկ�Ij1�.��ĢwH7���̲�A{�������~�j�����o߾��u�         ?   x�3�4202�50�52Q04�21�22��,.I���!׼����.#�J��2��b���� �8�         �  x��Qo�0���W����(&���U�6$ڡB��<�Ko�"q"۩ƿ������MS�!$"��rw�l��D�r<��Ap�.��P~^�V;�!�%7�;�� _x�#h�ņ|� �Lvd�+A�f?�ds�9Ӽ��5(�6@bb�%�V�*:j}3k�2�,���j9���ط^M�HЕ��J3])2�`�
�#��-ϭ0ݮ%K���4Y,�I��\)��Ll� �x_+[#Y��EQn�R=��t��ux�FaG>.�4N�{x��(s:I&�$y�f��A���(�`$2�C��Ϲ�J��LB�gS�Ay�����7�K�����|é��$y�1�xքO�px��~D#ߑ����h$�kD[nk�#W��h$�{D��VH�)�T�!�"�Ht��с+FH4�=��QMt�Jh@��alN�/�^�"5|ޕ&��&F���r	���,����^�	��*����n�0x)�y_B7q�;{�ū�1ƦЯ"O��<@��;�nAU�Vgk���4��Yv�M�f�L��9Y��cs���������<N� ��6� u�Rp�X�g��M:H�ɔ��6L�H�$���Y�o�G��!��e0< �2�e�,�Q}�����)�7m��;�H�)�t���Gc���&���7��'D�O�觪�!�h$��D�ut�u4}
D�o�8����Dw��v���D��������$��D�~������c+         �   x���1
�0 �99�������OЩ��%`�$Yr�֥�Һo}-�1�P����Bè�@<rL~�}׭1mn;��L�9�5d���z�[,�e$���o�S�>�B`����67�������R� "�eM            x������ � �      	      x������ � �            x������ � �            x������ � �         �   x���A�0E��)� 
e���b`�fb'����Vn/�&m2���ߤK��,f�&�e�KVD�bQW�NZH�@Q
����"��l�Z�>�����q��L�6��C����k_v\�\�
�s�3*)~jE�I�N�`�"T4�� 8K������ ޵1|�            x������ � �      -      x������ � �      8   o   x��͡�@EQ����@i򒷻Y�G ����Sf�g���>kݚ��b����x�>�:٤�	�����E#Z��.�^ɾ�"���^}F��#b0��h�����z(����,$      :      x������ � �      /      x������ � �      >   `   x��̻�0E�ڙ���g�AC���
��#�h��n{��G�x-�hܖu��g��\(�2B�ޭ�֓���k�7��*�O����/��!�{g"�      <      x������ � �            x������ � �            x������ � �            x������ � �         b  x����k�0 �s�+r�Ԓ/��6(��S7(���l�*1��/V���MF�!$Ɨ�3/��!>Ĕ�Y 6e�E
v�*V�ëJ���G�Fá�e8_�Z~EZf�0��<C�΋M�p��Ȳ�v�;C��W퇫n��X}��:� Qi1?��s�廌/��YU��(��Ң�̓	��>wh���:��HV�G���onR�1����t���ݭ��61
ϣ2g�Cg�T.'w�]��J�B�f�g�:�`�z��_T�I�făش���SC�D�7�I�v�=͚e�����_��I��!��q��{�����,�hx#S1b�n15��w����uN�şu��x7�,�D
S�         �  x����N�0��ӧ�r�b�L���t
�ъ�;߸�E-9vd'HU�w�Yx�9qY�HV�a�����>���g_�Ь!��zy�J4��}���L�
�LR���r� 2?�0_��~��̀/�
�,�����q+� �u�d����3��'@
��ol�[E�(���Wf��C,89Y7�i dD�y��Re��ؕ�;=�w��6?=S�tW�ʻ����2�5�b"���p�K�������۱$]��ǩ��GH8�ͰY/�D(�����d�EA9B�"�#"�\,�ZH���6��q;8߯&u�cF���m�4���U������_���۱>�;ǻ�2�����w?ϟ&���6�?w�>ﯽq��wWw��=��y�x�%�
�pvE�~qu�mN��Ӥ?|¤�3�����ݞ�5��c�h�����#�*�	�T�]G�}y}A�[ �����n��U⇃��¿0�~ �r�g�����ms 8� �l�            x������ � �         K   x�3�4202�50�52Q04�20�2���,.I���!C=��ӄӐ�a����������9������� 1}�      !   �   x��5�4202�50�52Q04�21�22��,.I���!ϼ�Ĝ���Ĝ�".�4d�d&�pV�������eLXiPjVjrIj
�	a��E�e@�����fV �����.s��K���jA�����y%!E�y�i�E@M�$؀��Ѐ�@�0�b���� �      #   N   x�3�4202�50�52Q04�20�2���,.I���!gNNS=��Ӑ�a����������9�Y�D����� �      %      x������ � �      '      x������ � �      2   r   x���1
�0D�zs
/��d�@�$�������6��,XX�c�e~������6D��#�r��:��I�B�!ڕq4�2�Q Pa��ؠ�>B�#T�^�RLM�a���s��3(�      *      x������ � �     