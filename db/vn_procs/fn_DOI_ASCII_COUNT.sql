CREATE OR ALTER FUNCTION dbo.DOI_ASCII_COUNT(@s nvarchar(400))
RETURNS int
AS
BEGIN
    -- 문자열 내 ASCII(반각, UNICODE<128) 문자 수 반환. 메시지 정렬 패딩(3-N)용이라 3으로 상한 (음수 REPLICATE→NULL 방지)
    DECLARE @i int = 1, @cnt int = 0, @len int = LEN(ISNULL(@s, N''));
    WHILE @i <= @len
    BEGIN
        IF UNICODE(SUBSTRING(@s, @i, 1)) < 128 SET @cnt = @cnt + 1;
        SET @i = @i + 1;
    END
    RETURN CASE WHEN @cnt > 3 THEN 3 ELSE @cnt END;
END
