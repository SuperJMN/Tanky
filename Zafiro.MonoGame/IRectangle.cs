namespace SuperJMN.MonoGame.Common
{
    public interface IRectangle : IReadonlyRectangle
    {
        new double Left { get; set; }
        new double Top { get; set; }
        new double Width { get; set; }
        new double Height { get; set; }
    }
}