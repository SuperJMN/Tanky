using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace TankyReloaded
{
    public interface IStageObject
    {
        void Draw(SpriteBatch spriteBatch);
        double Left { get; set; }
        double Top { get; set; }
        double Width { get; set; }
        double Height { get; set;  }
        Rectangle Bounds { get; }
        IStage Stage { get; set; }
        void LoadContent(ContentManager content);
        void Update(GameTime gameTime);
        void CollideWith(IStageObject other);
    }
}