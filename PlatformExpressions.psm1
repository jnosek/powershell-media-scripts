enum MediaType {
    Photo
    MovingPhoto
    Video
    Screenshot
}

class MediaExpression {
    [string] $Name;
    [string] $Expression;
    [MediaType] $MediaType;

    MediaExpression($name, $expression, $mediaType){
        $this.Name = $name;
        $this.Expression = $expression;
        $this.MediaType = $mediaType;
    }
}

<#
Returns the default expression for already processed files
#>
function Get-DefaultExpressions
{
   $exps = @(
        [MediaExpression]::new(  
            "Default",
            "^(?<year>[0-9]{4})(?<month>[0-9]{2})(?<date>[0-9]{2})-(?<hour>[0-9]{2})(?<minute>[0-9]{2})(?<second>[0-9]{2})\.(?<ext>[a-z|A-Z]+)$",
            [MediaType]::Photo)
    );

    return $exps;
}

function Get-AndroidExpressions
{
    $exps = @(
        # default Android photo format legacy and current:
        # 
        # Legacy:  IMG_20190607_110809.jpg
        # Current: PXL_20210312_183124373.jpg
        #          PXL_20210312_183124373.NIGHT.jpg
        [MediaExpression]::new(    
            "AndroidDefaultPhoto",
            # include exclusion of MP.jpg
            "^[a-z|A-z]{3}_(?<year>[0-9]{4})(?<month>[0-9]{2})(?<date>[0-9]{2})_(?<hour>[0-9]{2})(?<minute>[0-9]{2})(?<second>[0-9]{2})[0-9]*(?:.(?!MP)[a-z|A-z]*)*\.(?<ext>jpg)$",
            [MediaType]::Photo),

        # current Android moving photo format:
        # 
        # Current: PXL_20210312_183124373.MP.jpg
        [MediaExpression]::new(    
            "AndroidCurrentMovingPhoto",
            "^[a-z|A-z]+_(?<year>[0-9]{4})(?<month>[0-9]{2})(?<date>[0-9]{2})_(?<hour>[0-9]{2})(?<minute>[0-9]{2})(?<second>[0-9]{2})[0-9]*\.MP.(?<ext>jpg)$",
            [MediaType]::MovingPhoto),

        # legacy Android moving photo format:
        # 
        # legacy: MPIMG_20210312_183124.jpg
        [MediaExpression]::new(    
            "AndroidLegacyMovingPhoto",
            "^MV[a-z|A-z]{3}_(?<year>[0-9]{4})(?<month>[0-9]{2})(?<date>[0-9]{2})_(?<hour>[0-9]{2})(?<minute>[0-9]{2})(?<second>[0-9]{2})[0-9]*\.MP.(?<ext>jpg)$",
            [MediaType]::MovingPhoto),

        # default Android video format legacy and current:
        # 
        # Legacy:  VID_20190718_153501.mp4
        # Current: PXL_20210312_183124373.mp4
        [MediaExpression]::new(    
            "AndroidDefaultVideo",
            "^[a-z|A-z]{3}_(?<year>[0-9]{4})(?<month>[0-9]{2})(?<date>[0-9]{2})_(?<hour>[0-9]{2})(?<minute>[0-9]{2})(?<second>[0-9]{2})[0-9]*(?:.[a-z|A-z]*)*\.(?<ext>mp4)$",
            [MediaType]::MovingPhoto),
        
        # default Android screenshot format:
        # 
        # Current: Screenshot_20171023-180252.png
        [MediaExpression]::new(    
            "AndroidDefaultVideo",
            "^Screenshot_(?<year>[0-9]{4})(?<month>[0-9]{2})(?<date>[0-9]{2})-(?<hour>[0-9]{2})(?<minute>[0-9]{2})(?<second>[0-9]{2})[0-9]*\.(?<ext>png)$",
            [MediaType]::Screenshot)        
    );

    return $exps;
}

function Get-iOSExpressions
{
    
}

Export-ModuleMember -Function Get-DefaultExpressions
Export-ModuleMember -Function Get-AndroidExpressions
Export-ModuleMember -Function Get-iOSExpressions