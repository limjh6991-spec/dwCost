CREATE OR ALTER FUNCTION dbo.Get_DOI_Glass_Thick(@품명 nvarchar(200))
RETURNS nvarchar(20)
AS
BEGIN
    -- [재구성 260730] 품명에서 유리두께(숫자+um/µm/㎛) 추출. 없으면 '' (원본 로직 미상, 패턴 추출 재구성)
    DECLARE @s nvarchar(200) = ISNULL(@품명, N'');
    DECLARE @pos int, @start int, @i int, @digits nvarchar(20) = N'';
    SET @pos = PATINDEX(N'%[0-9]um%', @s);
    IF @pos = 0 SET @pos = PATINDEX(N'%[0-9]µm%', @s);
    IF @pos = 0 SET @pos = PATINDEX(N'%[0-9]㎛%', @s);
    IF @pos = 0 RETURN N'';
    SET @start = @pos;  -- 숫자 마지막 자리 위치
    WHILE @start > 1 AND SUBSTRING(@s, @start-1, 1) LIKE N'[0-9]' SET @start = @start - 1;
    SET @i = @start;
    WHILE @i <= LEN(@s) AND SUBSTRING(@s, @i, 1) LIKE N'[0-9]'
    BEGIN SET @digits = @digits + SUBSTRING(@s, @i, 1); SET @i = @i + 1; END
    RETURN @digits;
END
GO
CREATE OR ALTER FUNCTION dbo.Get_DOI_고객코드(@품명 nvarchar(200))
RETURNS nvarchar(100)
AS
BEGIN
    -- [재구성 260730 스텁] 원본 품명→고객코드 매핑 로직 미상. dw_모델기본정보.MODEL_CODE의 fallback으로 품명 그대로 반환.
    RETURN ISNULL(@품명, N'');
END
GO
