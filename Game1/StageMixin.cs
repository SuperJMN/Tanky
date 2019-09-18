using Microsoft.Xna.Framework;

namespace TankyReloaded
{
    public static class StageMixin
    {
        public static Rectangle GetBounds(this IStage stage)
        {
            return new Rectangle(0, 0, (int) stage.Width, (int) stage.Height);
        }

        public static double ApplyDifferential(this GameTime time, double value)
        {
            return time.ElapsedGameTime.TotalSeconds * value;
        }

        public static double Apply(this double value, GameTime time)
        {
            return time.ElapsedGameTime.TotalSeconds * value;
        }
    }
}